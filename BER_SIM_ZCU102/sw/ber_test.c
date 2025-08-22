/*
 * BER Simulation Test Program for Zynq MPSoC
 * 
 * This program tests the BER simulation IP by accessing it through
 * memory-mapped I/O using /dev/mem interface.
 * 
 * Hardware Configuration:
 * - BRAM Base Address: 0xA0000000
 * - UART Base Address: 0xA0010000  
 * - Sim Controller Base Address: 0xA0020000
 * 
 * Register Map:
 *   Sim Controller (0xA0020000):
 *     0x00: Control register (start/stop/config)
 *     0x04: Index/status register
 *     0x08: Upper 32 bits of probability data
 *     0x0C: Lower 32 bits of probability data
 * 
 *   BRAM (0xA0000000): BER statistics storage
 *     0x00-0x07: total_bits (64-bit)
 *     0x08-0x0F: total_bit_errors_pre (64-bit)
 *     0x10-0x17: total_bit_errors_post (64-bit)
 *     0x18-0x1F: total_frames (64-bit)
 *     0x20-0x27: total_frame_errors (64-bit)
 * 
 * Author: Generated for ZCU102 Board
 * Date: 2025
 */

#define _POSIX_C_SOURCE 199309L
#define _XOPEN_SOURCE 600

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <getopt.h>
#include <math.h>  // For log10 function
#include <stdarg.h> // For va_list

/* Hardware Configuration */
#define BRAM_BASE_ADDR          0xA0000000ULL
#define UART_BASE_ADDR          0xA0010000ULL
#define SIM_CONTROLLER_BASE_ADDR 0xA0020000ULL
#define COMPONENT_SIZE          0x10000  // 64KB

/* Sim Controller Register Offsets */
#define SIM_CTRL_REG0_OFFSET    0x00    // Control register
#define SIM_CTRL_REG1_OFFSET    0x04    // Index/status register
#define SIM_CTRL_REG2_OFFSET    0x08    // Upper 32 bits probability
#define SIM_CTRL_REG3_OFFSET    0x0C    // Lower 32 bits probability

/* Control Register (REG0) Bit Mapping:
 * [31:17] - Reserved
 * [16:12] - MAX_ITERATIONS_2D (5 bits, 0-31)
 * [11:8]  - N_INTERLEAVE (4 bits)
 * [7:4]   - PRECODE_EN (0xF=enabled, 0x0=disabled)
 * [3:0]   - Control bits (0xF=start)
 */

/* BRAM Statistics Offsets */
#define BRAM_TOTAL_BITS_OFFSET      0x00
#define BRAM_BIT_ERRORS_PRE_OFFSET  0x08
#define BRAM_BIT_ERRORS_POST_OFFSET 0x10
#define BRAM_TOTAL_FRAMES_OFFSET    0x18
#define BRAM_FRAME_ERRORS_OFFSET    0x20

/* Test Configuration */
#define MAX_SIMULATIONS         18
#define BLOCK_LENGTH            64
#define PROBABILITY_ARRAY_SIZE  1152  /* 16 blocks * 64 values each */

/* Control Register Bits */
#define CTRL_START_BIT          0x01
#define CTRL_EPF_EN_BIT         0x02
#define CTRL_N_IL_MASK          0x1C
#define CTRL_RESET_BIT          0x08

/* Control Register Values */
#define DEFAULT_MAX_ITERATIONS  8            /* Default MAX_ITERATIONS for 2D RS decoder */
#define CTRL_FULL_STOP_VALUE    0x00000000  /* Complete stop - clear everything */
#define CTRL_RESET_ASSERT       0x00000008  /* Assert reset to BER IP */

/* 2^64 as a double used to normalise the PDF */
static const double TWO_POW_64 = 18446744073709551616.0;   /* 2^64 */
/* Signal variance for an 8-bit full-scale NRZ symbol (±127) */
static const double SIG_VAR    = (127.0 * 127.0) / 3.0;    /* 5382.0 */

/*───────────────────────────────────────────────────────────────────────────*/
/*  Compute SNR[dB] for a single 64-value threshold block                    */
/*───────────────────────────────────────────────────────────────────────────*/
static double compute_snr_db(const uint64_t *thr_block)
{
    double var_n = 0.0;          /* noise variance we are accumulating */
    uint64_t prev = 0;

    for (int k = 0; k < BLOCK_LENGTH; k++) {
        /* PDF of |n| at amplitude k  */
        uint64_t diff = thr_block[k] - prev;
        double     p = (double)diff / TWO_POW_64;

        var_n += p * (double)(k * k);   /* Σ p*k^2 */
        prev   = thr_block[k];
    }

    var_n *= 2.0;                /* ×2 for the ± sign symmetry          */
    double snr_lin = SIG_VAR / var_n;
    return 10.0 * log10(snr_lin); /* convert to dB                       */
}

/* Global variables */
static volatile uint32_t *sim_controller_regs = NULL;
static volatile uint32_t *bram_base = NULL;
static int mem_fd = -1;
static volatile int running = 1;
static volatile int force_exit = 0;
static FILE *log_file = NULL;
static int max_iterations = DEFAULT_MAX_ITERATIONS;  /* Configurable MAX_ITERATIONS for 2D RS decoder */

/* Probability arrays for different SNR conditions */
static uint64_t probability[PROBABILITY_ARRAY_SIZE] = {0x07dd7eb3784f5f00,0x0f89db212ce09280,0x17064839652f6300,0x1e53f16ef7e1f800,
0x2573fae615021200,0x2c6781a1ebea8000,0x332f9bb1340ac800,0x39cd58599f765c00,
0x4041c0423e096400,0x468dd59cd7c2a000,0x4cb2944e44c86c00,0x52b0f215c966dc00,
0x5889deb37c2d4000,0x5e3e440dbc2b1400,0x63cf0655bd26d800,0x693d042b2f84cc00,
0x6e8916bf096fcc00,0x73b411f576b3c800,0x78bec486f4975c00,0x7da9f8209ee0d800,
0x82767183b312f000,0x8724f0a44ecd6800,0x8bb630c76e1fb000,0x902ae8a02e7d2000,
0x9483ca6c5ae54800,0x98c1841045b66000,0x9ce4bf31f483c000,0xa0ee2153a22f6800,
0xa4de4bed9b6ac800,0xa8b5dc8779a97000,0xac756cd0c076c000,0xb01d92b8e1073800,
0xb3aee086a7c62000,0xb729e4ef17887800,0xba8f2b2bb5f78800,0xbddf3b104caf2000,
0xc11a99202275b000,0xc441c6a2afdef800,0xc75541b7d295e000,0xca55856b82754800,
0xcd4309c90b844000,0xd01e43edcfd6a800,0xd2e7a61b94407800,0xd59f9fca5ab80000,
0xd8469db9cd30c800,0xdadd0a023ba83800,0xdd634c25300b8000,0xdfd9c91d9a8de000,
0xe240e36f98f67000,0xe498fb37db5c5000,0xe6e26e3aa8b93000,0xe91d97f285aae000,
0xeb4ad19e7fadf000,0xed6a72501f0d2800,0xef7ccef901b3a800,0xf1823a782101f000,
0xf37b05a6c4b8b000,0xf5677f6524ff5800,0xf747f4a6bd7fc800,0xf91cb07e5383f800,
0xfae5fc29b0f6e800,0xfca41f1d161d9800,0xfe575f0e63d24000,0xffffffffffffffff,
0x0a09de1430109180,0x13b9150404ea1600,0x1d10d7732bd96500,0x26143b249cecb000,
0x2ec639ff62aad400,0x3729b30a2ed23200,0x3f416b5e0f31b400,0x47100f1092c04000,
0x4e983215ac432400,0x55dc51199d1a2800,0x5cded2533025c000,0x63a2064e8a32d400,
0x6a2828b0d2e40400,0x707360f4f6b3e800,0x7685c321c0645800,0x7c61507985fbb800,
0x8207f823a3529800,0x877b97cffa27c800,0x8cbdfc54adb7d800,0x91d0e2464ded7800,
0x96b5f68aa469a800,0x9b6ed6e653dd3800,0x9ffd12857876c000,0xa4622a7f7682d800,
0xa89f925622c3e800,0xacb6b0706e7ed800,0xb0a8de90bfbdd800,0xb4776a471cdd8000,
0xb823955f5116e800,0xbbae964b2e658800,0xbf1998890fdeb800,0xc265bd06be546000,
0xc5941a80d7ea0800,0xc8a5bddeda1d6000,0xcb9baa8beca62000,0xce76dacc8a7f3000,
0xd138401125622800,0xd3e0c345defe6800,0xd671451f723f6000,0xd8ea9e656606f800,
0xdb4da039a1dca000,0xdd9b145d7c339000,0xdfd3bd745915a000,0xe1f85743ef326000,
0xe40996f2488b1000,0xe6082b419334c800,0xe7f4bcc9d5f0f000,0xe9cfee309baa3000,
0xeb9a5c5ea8377000,0xed549eb3c8210000,0xeeff4738cc837800,0xf09ae2cfc3919800,
0xf227f9627da15000,0xf3a70e0f6e204000,0xf5189f54f7417800,0xf67d273b2eb05000,
0xf7d51b7c2912e000,0xf920edaad9aaa000,0xfa610b5892e8e800,0xfb95de3934599800,
0xfcbfcc4611d64000,0xfddf37df9f881000,0xfef47fededd70000,0xffffffffffffffff,
0x0c4f3ff6bfbbcf00,0x180e94a4b9f7b200,0x234490b069427a00,0x2df779e7565fcc00,
0x382d4cc0914cd600,0x41ebbfb621a60000,0x4b3846774e2dd800,0x541814f5854c5c00,
0x5c90224d9b751800,0x64a52b8f006db400,0x6c5bb6627963d400,0x73b81391db947400,
0x7abe617231eef400,0x81728e31a790e800,0x87d85a0a812bd800,0x8df3595c60534000,
0x93c6f6acfd4e7000,0x99567491764ed000,0x9ea4ef8145d1a800,0xa3b55f93e5734000,
0xa88a9a2a168a6800,0xad275383be808000,0xb18e204339fc0000,0xb5c176deff941800,
0xb9c3b10260df2000,0xbd970cde2f3a7000,0xc13dae6a00a78800,0xc4b9a096c87fa000,
0xc80cd6736f899000,0xcb392c440f27f800,0xce40688c6bdb9000,0xd1243d0e44334800,
0xd3e647bc02740800,0xd68813a058c2d800,0xd90b19bb49683800,0xdb70c1d516d8b000,
0xddba634791882000,0xdfe945be342a3000,0xe1fea1ed79dce000,0xe3fba241d4d18800,
0xe5e16386a7599800,0xe7b0f5859cc37000,0xe96b5b9ebb2fc800,0xeb118d5983757000,
0xeca476ef70465000,0xee24f9d02213d000,0xef93ed1f81a5e800,0xf0f21e2e1ff85000,
0xf24050ec16b78000,0xf37f4056a9a46000,0xf4af9ee0e6355800,0xf5d216d77bfed800,
0xf6e74ac005c0b800,0xf7efd5b3f868c000,0xf8ec4bb76aeb6800,0xf9dd3a0be780c000,
0xfac3277f749c4800,0xfb9e94b801d7e800,0xfc6ffc7b63062800,0xfd37d3f401b19800,
0xfdf68af26b78e800,0xfeac8c2be1f5b800,0xff5a3d760f2f2000,0xffffffffffffffff,
0x0eabaf96f7f5bf80,0x1c85944950863c00,0x29996627f861c400,0x35f235ae7483ea00,
0x419a751f5915cc00,0x4c9c015ae4637800,0x57002a3736358c00,0x60cfba6132f17000,
0x6a12feccbcec8000,0x72d1cdba8f0c4c00,0x7b138d59a9cf4800,0x82df3a09eee10800,
0x8a3b6c4537244800,0x912e5e33e35ef800,0x97bdf0f1a0324000,0x9defb186d283f000,
0xa3c8dd9ae1c09000,0xa94e67e3592de800,0xae84fc53a0b3e000,0xb3710410d7db7800,
0xb816a92d2b1cd800,0xbc79da2dcbc39000,0xc09e4d5e85893800,0xc48783f5c265f000,
0xc838cd0ba4d72000,0xcbb54866badcf800,0xceffe920a80f1000,0xd21b782503492000,
0xd50a968c8475c800,0xd7cfbfd680cc4000,0xda6d4c0297536000,0xdce5718c5492b000,
0xdf3a474a7af0f800,0xe16dc63385418000,0xe381cb08e25ae000,0xe57817ea532ef800,
0xe75255d2c0ab0000,0xe91215ffcb95e000,0xeab8d34546a3e000,0xec47f34db9f7a000,
0xedc0c7c8ff3e1000,0xef248f89f66c4000,0xf074779444d92800,0xf1b19c1b02ecd800,
0xf2dd09712fde9800,0xf3f7bcecb6f24800,0xf502a5bcc6484000,0xf5fea5b42c97f000,
0xf6ec9208690c9000,0xf7cd34060eea9800,0xf8a149bb159d1800,0xf9698697a5436800,
0xfa269405e7cb7800,0xfad911f95f0b0800,0xfb819776391d9000,0xfc20b31115865800,
0xfcb6eb67a730d000,0xfd44bf92995f8000,0xfdcaa79117e66000,0xfe4914ae55ab0800,
0xfec071e16750e800,0xff312427c32a7800,0xff9b8adab3016000,0xffffffffffffffff,
0x112190b10edc4100,0x212159739330a600,0x3012801038115000,0x3e06e66ba42c7600,
0x4b0f3fed3ddb7000,0x573b257beb421c00,0x62992828ba268800,0x6d36e29dc68a1000,
0x772109663d28d400,0x80637a22f6189800,0x890949bdda25c800,0x911cd1ad11bab000,
0x98a7bc55dca0f000,0x9fb3109de570c800,0xa6473cb8e8c1e800,0xac6c203f9e042800,
0xb229159bf5321000,0xb784fad5f04d8000,0xbc8639cba0d58000,0xc132cfde1f3c8800,
0xc590551cac052800,0xc9a402f68ec7a000,0xcd72ba7bb6443000,0xd1010a33951df800,
0xd453339138469800,0xd76d300b1decd800,0xda52b5dce5594800,0xdd073c7889094000,
0xdf8e00ac740cd000,0xe1ea088369be8800,0xe41e26e2e2ee8000,0xe62cfeec3529c800,
0xe81907248f85f800,0xe9e48c6793ee3800,0xeb91b4a81409e800,0xed2281823d28a800,
0xee98d2a246e53800,0xeff6680284239800,0xf13ce4038573d000,0xf26dcd60ce7cb800,
0xf38a910475ad0800,0xf49483bbddd7a000,0xf58ce3cf94666000,0xf674da803c44c800,
0xf74d7d6a4d634000,0xf817cfd252941000,0xf8d4c3db3361c000,0xf9853ba7fd381800,
0xfa2a0a6a86af9000,0xfac3f56030e0e000,0xfb53b4bdf53ef800,0xfbd9f48cda790800,
0xfc575577d83be000,0xfccc6d8c203a4800,0xfd39c8ecb29c7800,0xfd9fea7a14c1d000,
0xfdff4c6ef30ca000,0xfe5860f2692c9000,0xfeab92a09ff94000,0xfef9450a645d8800,
0xff41d52c5005c800,0xff8599de126cf000,0xffc4e43a5f77b000,0xffffffffffffffff,
0x13b308ee6a5e6300,0x25e463f5949be000,0x36b190049a90ac00,0x4635ca905cb37400,
0x548a3bbd82be9c00,0x61c61f29d6334000,0x6dfee99715362c00,0x79486bb44f9c4400,
0x83b4f23e34588000,0x8d5563aa654ad800,0x96395b8debae7800,0x9e6f43eb39a2a800,
0xa6046c90bf8b7800,0xad0520adf8ce6800,0xb37cbac1eda37000,0xb975b7037aa1b800,
0xbef9c46136039000,0xc411d43482532000,0xc8c628c142977000,0xcd1e6299b1c35000,
0xd1218cfc12ee4800,0xd4d6293e46d94800,0xd8423959cabab800,0xdb6b49a939cd7000,
0xde5679e71c55c000,0xe108857c99a39000,0xe385cb2d85100000,0xe5d2542e36433800,
0xe7f1daaea9884800,0xe9e7cfe5840d9800,0xebb761a4c83c3800,0xed637f81467f3800,
0xeeeedf9525ad8800,0xf05c02e53aafc000,0xf1ad39704fe3d000,0xf2e4a5eef1384000,
0xf4044149d11b7000,0xf50dddcc6359d000,0xf6032a18dd1d5800,0xf6e5b3e263c0d800,
0xf7b6ea71d66c6800,0xf87820f947deb800,0xf92a90b9edd39000,0xf9cf5b0001a30000,
0xfa678af7c983b800,0xfaf4175ec2e2b000,0xfb75e413ac199800,0xfbedc387f6184000,
0xfc5c7814f4fac800,0xfcc2b536f8b80800,0xfd2120b04cc4c000,0xfd785395f6774000,
0xfdc8db47e5e15000,0xfe133a562b849800,0xfe57e954a67f0000,0xfe97579e82611000,
0xfed1ec0ac1a18000,0xff080592f9634800,0xff39fbed4ce14000,0xff68201aa225c000,
0xff92bce9f69cb000,0xffba1771a86d0000,0xffde6f7f793d9800,0xffffffffffffffff,
0x150858e782580200,0x28583377ef15a800,0x3a13991bae7b0600,0x4a5ba081edf9f400,
0x594eab5d3d245c00,0x67089f1506f9b000,0x73a318d3b2407400,0x7f359d528bf8b400,
0x89d5c4bcac942000,0x939762fabcafe000,0x9c8cacb2caebf800,0xa4c659413dac9000,
0xac53c1ea4597d800,0xb342fe7e05f4f000,0xb9a0ffa4e5005000,0xbf79a70516f57800,
0xc4d7dd6e72cb4000,0xc9c5a735eff2e000,0xce4c36e6c9efe800,0xd273fe6c2b08e000,
0xd644bed364cf3000,0xd9c596c41e805800,0xdcfd0fc979645800,0xdff12a84f5d18800,
0xe2a769e1dc463800,0xe524dd5e1149e800,0xe76e2a7b850a8000,0xe987956bddbc3000,
0xeb7509068ab66800,0xed3a1e181b6db000,0xeeda22187e47a000,0xf0581d54ad984000,
0xf1b6d8974ac9a000,0xf2f8e25ab6d46000,0xf420938e5a0ba800,0xf53013f80230b000,
0xf6295e3983516800,0xf70e43821cc59000,0xf7e06ef2866e6800,0xf8a168b9fa09e800,
0xf95298f207e69800,0xf9f54a3e8c977800,0xfa8aac36ad8ec800,0xfb13d59b5bf20000,
0xfb91c65f7ec83800,0xfc0569858f28a000,0xfc6f96d621a61000,0xfcd114728f4b1800,
0xfd2a9846ad87a000,0xfd7cc95c46f8b000,0xfdc84112ce819800,0xfe0d8c3d925ba800,
0xfe4d2c2a852b1000,0xfe87979387774000,0xfebd3b7bf3c6c800,0xfeee7bfc0ac94800,
0xff1bb4fbbb273000,0xff453ade2181b800,0xff6b5b1f00a96800,0xff8e5ce357e35800,
0xffae817e250b1000,0xffcc04ea4a4c8800,0xffe71e3a7aed4800,0xffffffffffffffff,
0x1666b589b09cac00,0x2ad90f4ad663f400,0x3d82b563010e1c00,0x4e8b80d149e6d000,
0x5e17d088fbf42800,0x6c48d719da59cc00,0x793ce191d4562000,0x850f982f7ea5a000,
0x8fda396f75a9a800,0x99b3cff2be344800,0xa2b163b13a940000,0xaae626e13eed7000,
0xb2639ef425ac1000,0xb939c9ff67451800,0xbf7740e215d41000,0xc529566fa4f16000,
0xca5c33e289a74800,0xcf1af2d370049800,0xd36fb4ec77166800,0xd763b98b0dbdd000,
0xdaff717ea08bf800,0xde4a910e41240800,0xe14c206bc1fae000,0xe40a8ab765cd5800,
0xe68babb431a57000,0xe8d4dc4a24388000,0xeaeafdf107d4e800,0xecd2851c3f87b000,
0xee8f82bdcfa22000,0xf025acf4f0c88800,0xf19866fab711c800,0xf2eac85db8b20000,
0xf41fa39c25bdf000,0xf5398c2a69a0b800,0xf63adbf33403d000,0xf725b85ca7868000,
0xf7fc16dd66539800,0xf8bfc12b45381800,0xf972590c9355a000,0xfa155bd41d142000,
0xfaaa258f5ae6f800,0xfb31f3ed964c7000,0xfbade8e637c12000,0xfc1f0d23e5ef5000,
0xfc865239a0059800,0xfce494a689c8a800,0xfd3a9dacb6ae7800,0xfd8924fee1399800,
0xfdd0d248a416c800,0xfe123e947a719800,0xfe4df59283e2a000,0xfe8476c2c5a92000,
0xfeb6368566015000,0xfee39f1326d8e800,0xff0d1160326c6800,0xff32e5eb1e0d1000,
0xff556d79dd0f6000,0xff74f1c637515800,0xff91b61b33948000,0xffabf7e4c5c69000,
0xffc3ef32f4009800,0xffd9cf318a400800,0xffedc6955c6e6000,0xffffffffffffffff,
0x17ceeb86db34ec00,0x2d681e014ab52400,0x410019ea1a98ac00,0x52c68205458ac400,
0x62e68d2fa3c34000,0x71876f6ebd9e8000,0x7eccb9402e719400,0x8ad6ae104eedf800,
0x95c292aa5c767800,0x9faaf460cfe29800,0xa8a7e99ae2e8a000,0xb0cf4c6434b6e800,
0xb834ef8ced230000,0xbeeacedb86d3c800,0xc5013ac56bcdc800,0xca870018afa52000,
0xcf898bf754e26000,0xd4150c7b97deb800,0xd8348e549ac06800,0xdbf217a37093f800,
0xdf56c059d6d8c800,0xe26ac855dcf92800,0xe535ab703952b800,0xe7be33ae0e4d4000,
0xea0a89c25b617800,0xec2044073ae01800,0xee04741353c71800,0xefbbb30c85f13000,
0xf14a2cd5c6344000,0xf2b3aa335821b000,0xf3fb99fe0d4de000,0xf525197be826e000,
0xf632fbf26ce6f000,0xf727d1850908f000,0xf805ed70443e2000,0xf8cf6bb0e1182800,
0xf9863624aba25000,0xfa2c09316d958000,0xfac277fd57941800,0xfb4af043221a1000,
0xfbc6bdcb35008800,0xfc370d9247466000,0xfc9cf0a5202ae800,0xfcf95eb86ca15800,
0xfd4d3882f7038000,0xfd9949dff91d7800,0xfdde4bbeb8c68800,0xfe1ce5e423f2e800,
0xfe55b082b1540800,0xfe8935ac6526b800,0xfeb7f2a27dc44000,0xfee25905f80c8000,
0xff08cfebcffed000,0xff2bb4d79d206000,0xff4b5c9eebf7f800,0xff6814377d595800,
0xff82217260ece800,0xff99c3a5b1d5c000,0xffaf3446921f3000,0xffc2a774db4dc000,
0xffd44c79d7afc800,0xffe44e3b3884a000,0xfff2d3a360783000,0xffffffffffffffff,
0x1942b6e79e7f6100,0x30082a450b8f7c00,0x448f26b7a50db800,0x571048988ba86000,
0x67be981a0a5f6c00,0x76c81604653c4400,0x84563a9430820000,0x908e67d81203c800,
0x9b9250c953a57000,0xa580563b99330000,0xae73daa40701c000,0xb6858d9ee4e87000,
0xbdcbb00404675000,0xc45a5145aa86d800,0xca4386c33d6cf000,0xcf979da847e39800,
0xd46547e15c0b8000,0xd8b9c4a2d0c1b000,0xdca104f11d780000,0xe025cc8f94b29000,
0xe351cfb04faa7000,0xe62dcdb72a5b7000,0xe8c1a9599dd38000,0xeb147e5e00b45000,
0xed2cb536276d2800,0xef1014ab74aef800,0xf0c3d1cd16b1f000,0xf24c9e4c6061c000,
0xf3aeb56ed92d4000,0xf4ede7b9b7162000,0xf60da576f1f35800,0xf7110830f2efd800,
0xf7fadb3f07698800,0xf8cda37a2a8dd800,0xf98ba62f664fb000,0xfa36ef62f42d8000,
0xfad1577562edf000,0xfb5c883a52cb2000,0xfbda018ed0c49800,0xfc4b1d7bf7c47000,
0xfcb113f13f1c4000,0xfd0cfe20be2a2000,0xfd5fd986a99bd800,0xfdaa8aa464fa6000,
0xfdeddf76b0677800,0xfe2a91adbc796000,0xfe6148ad42de2800,0xfe929b5a280c6800,
0xfebf11ba9f1b1000,0xfee7266d4b650000,0xff0b47fb6a849000,0xff2bda09ab401000,
0xff49366afa195800,0xff63ae183959a800,0xff7b8a0f8fc42800,0xff910c1db5c74800,
0xffa46f936c547000,0xffb5e9e911d08800,0xffc5ab52183ed000,0xffd3df41f3527800,
0xffe0ace3ecffe800,0xffec37872b06c000,0xfff69f000f5bd800,0xffffffffffffffff,
0x1ac2805899e65a00,0x32b988555e4fec00,0x482fd154d11e4800,0x5b6846d3b1d39400,
0x6c9ed715ea34a000,0x7c092e0498113400,0x89d75c87dbddf000,0x96346e663b440000,
0xa146f07ce74bd000,0xab3168f367629800,0xb412c2e175016000,0xbc06aeb6aee55000,
0xc325f890bc87b000,0xc986d58d15887800,0xcf3d29078326d000,0xd45ac29d4402d000,
0xd8ef95b62dbae000,0xdd09eb40f6331000,0xe0b68e3db8813800,0xe400f3a1972e5000,
0xe6f35e0fdc3ea800,0xe996fdd7fa038800,0xebf40d9c2d98f000,0xee11ebfa18dc8000,
0xeff7328555215800,0xf1a9ca5ba4d19800,0xf32efe92ee837800,0xf48b8cba786ef000,
0xf5c3b3a2dac6b800,0xf6db409abf82f800,0xf7d59b49b5ecb000,0xf8b5d04e10abf000,
0xf97e9abee8cef000,0xfa326cafeb2cc800,0xfad376d17ce24000,0xfb63af44fdcc7000,
0xfbe4d7ba742d0800,0xfc5882eab3513000,0xfcc0197f11374800,0xfd1cde75f692d000,
0xfd6ff311fba13000,0xfdba5a5fd60b5800,0xfdfcfc5e14181000,0xfe38a8d07bbc0800,
0xfe6e19c7dd0ad000,0xfe9df5e63bfab800,0xfec8d26662769800,0xfeef34ed2eca7800,
0xff11952a4944f000,0xff305e4d545ff800,0xff4bf05423105000,0xff64a13607530800,
0xff7abdefde3aa800,0xff8e8b741d44e000,0xffa04781cd77e800,0xffb02965129a0000,
0xffbe62a396d37800,0xffcb1f96f458d800,0xffd687f6fe953000,0xffe0bf559a030800,
0xffe9e58da4da8800,0xfff217264a66c800,0xfff96dabf6b5f800,0xffffffffffffffff,
0x1c4f97b821edd200,0x357e1f6d3fb78600,0x4be42156e747a000,0x5fd05e6bbb542000,
0x7188e34813c16800,0x814bfe79a772d000,0x8f511b923b4e8800,0x9bc986039b0fe800,
0xa6e11671fda17800,0xb0beccde3cca4800,0xb98559c5ecbad000,0xc153981b76a56800,
0xc844f9c30f622000,0xce71e811fccb2000,0xd3f019a37359c000,0xd8d2deb0d55a6000,
0xdd2b64f9c1f22800,0xe108f42ab6e5c800,0xe4792396a4448000,0xe7880a005800a800,
0xea40681bc6949800,0xecabce5ca3a96800,0xeed2be973904e000,0xf0bcc9e9b8b6d800,
0xf270ab5735ec4000,0xf3f45f71d002f000,0xf54d39674497a000,0xf67ff5b9eaf36800,
0xf790cae7ed21f000,0xf883783b4c531800,0xf95b52f6c5646800,0xfa1b520de8c66000,
0xfac618919a2bc000,0xfb5dfef59e8aa800,0xfbe51b4fd1ef6000,0xfc5d48ae0436a000,
0xfcc82d9c474ff800,0xfd2741f29fe23000,0xfd7bd3fe800e2800,0xfdc70d1a32add000,
0xfe09f5c25bdf8000,0xfe457937eae2d800,0xfe7a68bb42fed000,0xfea97e6bf7c34800,
0xfed35fd73784c000,0xfef8a03de1056800,0xff19c29a42ec2000,0xff373b6ca1752000,
0xff517254d5922000,0xff68c37ea5b88000,0xff7d80e5d96b9800,0xff8ff3767afa0000,
0xffa05c0d3cf2e800,0xffaef45b88d31000,0xffbbefb258c4e800,0xffc77bb6a5ae6800,
0xffd1c101e3f2a800,0xffdae3b0c32e8800,0xffe303e226d91800,0xffea3e281637c800,
0xfff0abec30bd1800,0xfff663c90805c000,0xfffb79d9999e2000,0xffffffffffffffff,
0x1deb4a320bd2bf00,0x3857be0ae3e0c800,0x4fade6d6a20fd000,0x644a191da0857400,
0x767ddff182d09800,0x86913f8c9ef6a800,0x94c3d24038252800,0xa14dc418dc2a4800,
0xac60b11c80693000,0xb6286991a9ab2800,0xbecb9f582fbfb800,0xc66c7f0173e35800,
0xcd293705c0696800,0xd31c6f2dc4262000,0xd85db2089c94a000,0xdd01ca0faf6e9000,
0xe11b13e8d4fcd800,0xe4b9c70c46f49000,0xe7ec35edc1e25000,0xeabf06a6b28a8800,
0xed3d6501a0611800,0xef712eacd4f88800,0xf1631a431e67b000,0xf31ad9c51c9dd800,
0xf49f390b7e9de800,0xf5f638aaa53bf800,0xf72525b20e350000,0xf830aea57c9ca000,
0xf91cf602d97f6800,0xf9eda29e15c80000,0xfaa5ee13c6994800,0xfb48b18ba5871800,
0xfbd870fd70769800,0xfc576524bf0b6800,0xfcc7844b2e09c000,0xfd2a8a0ba762f000,
0xfd81fe2d7d86d000,0xfdcf3ab279fd1000,0xfe13712fd4047000,0xfe4faf873777d800,
0xfe84e4128b71a000,0xfeb3e152f94a2800,0xfedd6131c6ff0000,0xff0207dfe4296000,
0xff22665f87b19000,0xff3efcc1e86d7000,0xff583c21ee922000,0xff6e8863b2af0800,
0xff8239bfb4b26800,0xff939e1fe69e8800,0xffa2fa53efe82800,0xffb08b216d1f9800,
0xffbc86346108d000,0xffc71af38e6f0000,0xffd0733c02dc1000,0xffd8b406b8347800,
0xffdffdfadc882800,0xffe66def02d8d000,0xffec1d5b3bf94800,0xfff122bddaf16000,
0xfff591f47394e000,0xfff97c8a7367e800,0xfffcf1fe8bc88000,0xffffffffffffffff,
0x1e3eeafb7358e000,0x38eb529b75785200,0x50713a26d4319800,0x652fe3029c464800,
0x777b4e6d829fb800,0x879d91ac488b3000,0x95d802089ec51800,0xa2643d61587ee800,
0xad75137b4442e000,0xb73753c377a02800,0xbfd282c4437e6000,0xc7697a2b9df6b800,
0xce1af5eb0518f800,0xd40210ac54a3d000,0xd936b19389839800,0xddcded09e78ce800,
0xe1da5a1a7757c800,0xe56c5db986c7c800,0xe8926d280337e800,0xeb59487f8319d000,
0xedcc2e541453a000,0xeff5093ce430e000,0xf1dc97fc23ef4800,0xf38a90e8c5cdc800,
0xf505c12979dd1000,0xf654283f61dc4800,0xf77b105003984000,0xf87f2390d50ed000,
0xf9647f2b1faf1800,0xfa2ec3e4b9647800,0xfae124d109338000,0xfb7e7445d575d000,
0xfc092f4852f0a800,0xfc8387a0b9a73000,0xfcef6cbd2d4a0800,0xfd4e9387f5640000,
0xfda27d50c1594000,0xfdec7de4f4c5b800,0xfe2dc0efaa945000,0xfe674eb732e5c000,
0xfe9a104b3dc05800,0xfec6d334a01e8800,0xfeee4cb5a11bc000,0xff111ca7f99c0000,
0xff2fd00422b8b000,0xff4ae31c302e8000,0xff62c3933e707000,0xff77d2196afd4800,
0xff8a63f35cccd800,0xff9ac4538e534800,0xffa9358acf555800,0xffb5f214cfa3b800,
0xffc12d84f22fe800,0xffcb1557277cb800,0xffd3d1a81d281800,0xffdb85d7ac682000,
0xffe25118193d4000,0xffe84eec666bd000,0xffed9797bdcc2000,0xfff2407fb0149800,
0xfff65c82d9f89000,0xfff9fc454d79a800,0xfffd2e73f4d79800,0xffffffffffffffff,
0x1e9432ba922cfc00,0x398199ad331f8c00,0x5137d5878412b400,0x66193284b88a5800,
0x787c3fea3a2bdc00,0x88ad36dd32eaf800,0x96ef365e8ab87800,0xa37d598b43797000,
0xae8baca2b1ece000,0xb84804ca53d9c000,0xc0dabe0db861e800,0xc86762ae1fd47800,
0xcf0d3e776a0a7800,0xd4e7e07d17521800,0xda0f8d5930d5e000,0xde99a3c6b3ed8000,
0xe298f5388d9d8800,0xe61e13dc6648b000,0xe937974ca2c28800,0xebf2590e61c41000,
0xee59a9d63b214000,0xf0778070940d6000,0xf254a30ffd1d2800,0xf3f8cbacd632c000,
0xf56ac80d01d9a800,0xf6b095f87008e800,0xf7cf7c0f6d24f800,0xf8cc1fa9abb45000,
0xf9aa9818b3a86800,0xfa6e7f9d8e696800,0xfb1b0257fe194800,0xfbb2eb6d293ee800,
0xfc38b09c3f6cc800,0xfcae7c7118da3800,0xfd16373f174ec800,0xfd718f0982678000,
0xfdc1fe7a2738f000,0xfe08d3031931b800,0xfe473244ffac2000,0xfe7e1ed05289d000,
0xfeae7c553beb6000,0xfed913537a83d800,0xfefe94598d6a1000,0xff1f9ae09f097000,
0xff3cafd1095ec800,0xff564bb9e35b2800,0xff6cd8c4c8383800,0xff80b46df094f800,
0xff923107bdc94800,0xffa1970ffe024800,0xffaf265c6fe09000,0xffbb17236360f800,
0xffc59ae4c115c000,0xffcedd373db53000,0xffd7047d0ca83800,0xffde3282feae5800,
0xffe4850ca038c800,0xffea164f9c59e800,0xffeefd6063c91800,0xfff34e91da666000,
0xfff71bc997e00800,0xfffa74ca18bf7800,0xfffd6774136ce800,0xffffffffffffffff,
0x1ee95e25f2d7a000,0x3a177677cf443800,0x51fd9a1e654ce000,0x67012e92d8df9c00,
0x797b5bd096defc00,0x89ba8698ce073000,0x98039d0c48377000,0xa4933b1ec5069000,
0xaf9eabbc9de4b000,0xb954cae5b3adf000,0xc1decc7cf1fdc000,0xc960eb17e7050800,
0xcffb01b41bca7800,0xd5c912de5093f800,0xdae3bf8907e68000,0xdf60af8a920cd800,
0xe352ed7dedc12000,0xe6cb378c4e2ae000,0xe9d8467607d77000,0xec870c0845fd2000,
0xeee2ea0887af6800,0xf0f5e27ee74f4800,0xf2c8c22c0dbfa800,0xf46345def7619000,
0xf5cc3b48f1a91800,0xf7099ddb18f71800,0xf820b027ce2a4800,0xf9161233d2b90800,
0xf9edd515ba60e800,0xfaab8c36f36cd800,0xfb525c7f99be2000,0xfbe509ad72869800,
0xfc66020ea97a1000,0xfcd768d21334e800,0xfd3b1f18b6b0c800,0xfd92cbef17619800,
0xfddfe35014928800,0xfe23ac4f1d216000,0xfe5f4683df71c000,0xfe93aece75252800,
0xfec1c388436ba800,0xfeea483357d36000,0xff0de8b7e4004800,0xff2d3c3d978d3000,
0xff48c7acee828800,0xff60ffe31542b800,0xff764ba1ba587000,0xff89054305c48000,
0xff997c38ef78b000,0xffa7f65e4f630000,0xffb4b11f3d18c800,0xffbfe27da88e8000,
0xffc9b9f67d7f0000,0xffd2614b1daca800,0xffd9fd3288cc4000,0xffe0adf521b80000,
0xffe68ff5a5ce6000,0xffebbc299b981000,0xfff0488337aac800,0xfff4484e790fb800,
0xfff7cc8308389800,0xfffae40c33de1800,0xfffd9c083d33e000,0xffffffffffffffff,
0x1f3f4d4f54958400,0x3aae7293a27b5800,0x52c48eaa18d5f800,0x67ea37248cfd2000,
0x7a7b3e65b67f5c00,0x8ac84253229b0800,0x99180a6006da1000,0xa5a8bae0d9ad0800,
0xb0b0e2de1e8f1800,0xba6068f9fc114800,0xc2e15b6d3a18a800,0xca58a6a2c0d80800,
0xd0e6b58a7c95b000,0xd6a7fe5bc89a4800,0xdbb57e2a909b2000,0xe0252567c2b13800,
0xe40a372430a2a800,0xe7759cb381994800,0xea762f1a5bb5c800,0xed18f7869c18c800,
0xef6967e98b902800,0xf1718ca9d5225800,0xf33a384505e57000,0xf4cb299e08adf000,
0xf62b2d9ef1d85000,0xf7603cc0235bd000,0xf86f94f4ff55f000,0xf95dd06eb9f12800,
0xfa2ef9981f01f000,0xfae69ca1104d1000,0xfb87d6e5eac32800,0xfc156475b51f5800,
0xfc91abf1d0e28800,0xfcfec8fabc2af800,0xfd5e95572849d000,0xfdb2b0fd22e6c800,
0xfdfc892035fde800,0xfe3d5e632101c800,0xfe764a48106cf000,0xfea843f6f0d69000,
0xfed4246e98f06000,0xfefaaa32fe294000,0xff1c7c886f102800,0xff3a2e49db54f000,
0xff5440667af46800,0xff6b2411a5489800,0xff7f3cae56d7d800,0xff90e17ebc1ac800,
0xffa05f1f12ffd800,0xffadf8d2504b9000,0xffb9e9a62d338000,0xffc46573914f7800,
0xffcd99bfb23e6800,0xffd5ae81ba7e1000,0xffdcc6d051ac7800,0xffe30179f7af9000,
0xffe8798ac84ce800,0xffed46c1ec008000,0xfff17df8b4027000,0xfff5317d212fa000,
0xfff871615ee8d000,0xfffb4bc18b02a800,0xfffdcd00f9c55000,0xffffffffffffffff,
0x1f95ff119bbf2500,0x3b468a719df39000,0x538caca94ef4a800,0x68d442bda1b90400,
0x7b7bdb7bf2d60800,0x8bd65ba6f86a4800,0x9a2c6e4ef8af9000,0xa6bdc7ba0c43b000,
0xb1c2407749a91000,0xbb6acd86b7e36000,0xc3e259e4bbe77000,0xcb4e853fae5a6800,
0xd1d04b270865d800,0xd784959b0d512800,0xdc84bd88329dd000,0xe0e6fb693258f000,
0xe4beca04463a5000,0xe81d3cfa4d0aa000,0xeb114ca87c52c000,0xeda818adce03e800,
0xefed223bc1c66000,0xf1ea7f3593192000,0xf3a907010e5ea800,0xf53079d02952e000,
0xf687a311f2ad2000,0xf7b477a3e3b7d000,0xf8bc3049bdbca800,0xf9a360e19063e000,
0xfa6e0cbb0404d800,0xfb1fb86c4aef3000,0xfbbb7973f65fd800,0xfc4403ed259b1000,
0xfcbbb692f413a800,0xfd24a548888d6000,0xfd80a25491645000,0xfdd1467934513000,
0xfe17f80c687d4000,0xfe55f13042021000,0xfe8c4546d2539000,0xfebbe5b9d8465800,
0xfee5a62b7d40c800,0xff0a4022be64e000,0xff2a5643d47e5800,0xff467722ea05a000,
0xff5f1fbdaaa51000,0xff74bda6ab87d800,0xff87b0ec50726000,0xff984dc3a1330000,
0xffa6ddfe7816c000,0xffb3a25388175000,0xffbed37dec5c0800,0xffc8a3393edae800,
0xffd13d1e96466000,0xffd8c7664146e000,0xffdf63919bdcc000,0xffe52efff195d800,
0xffea4371022a5000,0xffeeb7776c789800,0xfff29edcfc4d4000,0xfff60afa98ac3000,
0xfff90b0559557000,0xfffbac521a0d3000,0xfffdfa90b7edd000,0xffffffffffffffff};

/* Function prototypes */
static int initialize_hardware(char *prog_name);
static void cleanup_hardware(void);
static void signal_handler(int sig);
static int run_ber_simulation(void);
static void write_sim_controller_reg(uint32_t offset, uint32_t value);
static uint32_t read_sim_controller_reg(uint32_t offset);
static uint64_t read_bram_64bit(uint32_t offset);
static void load_probability_array(int sim_no);
static void print_ber_results(int sim_no);
static void reset_hardware(void);
static void stop_simulation_hardware(void);
static void force_controller_reset(void);
static int is_hardware_running(void);
static void print_hardware_status(void);
static double compute_snr_db(const uint64_t *thr_block);
void print_snr_for_all_blocks(const uint64_t *array, size_t length);
static void clear_bram_counters(void);
static int initialize_log_file(void);
static void cleanup_log_file(void);
static void log_printf(const char *format, ...);
static void get_timestamp(char *buffer, size_t buffer_size);

/* Utility functions for timestamped logging */
static void get_timestamp(char *buffer, size_t buffer_size)
{
    time_t now;
    struct tm *local_time;
    
    time(&now);
    local_time = localtime(&now);
    
    strftime(buffer, buffer_size, "%Y-%m-%d %H:%M:%S", local_time);
}

static int initialize_log_file(void)
{
    time_t now;
    struct tm *local_time;
    char filename[256];
    
    time(&now);
    local_time = localtime(&now);
    
    strftime(filename, sizeof(filename), "run_%Y%m%d_%H%M%S.log", local_time);
    
    log_file = fopen(filename, "w");
    if (log_file == NULL) {
        perror("Error opening log file");
        return -1;
    }
    
    printf("Log file created: %s\n", filename);
    return 0;
}

static void cleanup_log_file(void)
{
    if (log_file != NULL) {
        fclose(log_file);
        log_file = NULL;
    }
}

static void log_printf(const char *format, ...)
{
    va_list args1, args2;
    char timestamp[32];
    
    get_timestamp(timestamp, sizeof(timestamp));
    
    va_start(args1, format);
    va_copy(args2, args1);
    
    /* Print to console with timestamp */
    printf("[%s] ", timestamp);
    vprintf(format, args1);
    
    /* Print to log file with timestamp if available */
    if (log_file != NULL) {
        fprintf(log_file, "[%s] ", timestamp);
        vfprintf(log_file, format, args2);
        fflush(log_file);
    }
    
    va_end(args1);
    va_end(args2);
}
static int initialize_log_file(void);
static void cleanup_log_file(void);
static void log_printf(const char *format, ...);
static void get_timestamp(char *buffer, size_t buffer_size);

int main(int argc, char *argv[])
{
    int opt;
    
    /* Initialize log file */
    if (initialize_log_file() < 0) {
        return 1;
    }
    
    /* Set up signal handler */
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    /* Parse command line arguments */
    while ((opt = getopt(argc, argv, "hsri:")) != -1) {
        switch (opt) {
            case 'h':
                log_printf("BER Simulation Test Tool\n");
                log_printf("Usage: %s [options]\n", argv[0]);
                log_printf("Options:\n");
                log_printf("  -h      Show this help\n");
                log_printf("  -s      Show hardware status only\n");
                log_printf("  -r      Force controller reset using FSM mechanism\n");
                log_printf("  -i N    Set MAX_ITERATIONS for 2D RS decoder (1-31, default 8)\n");
                log_printf("  (no options) Run BER simulation with default settings\n");
                cleanup_log_file();
                return 0;
            case 's':
                /* Status mode - just initialize and show current state */
                if (initialize_hardware(argv[0]) < 0) {
                    cleanup_log_file();
                    return 1;
                }
                log_printf("BER Simulation System Status:\n");
                print_hardware_status();
                print_ber_results(-1);
                // cleanup_hardware();
                // cleanup_log_file();
                return 0;
            case 'r':
                /* Force controller reset mode */
                if (initialize_hardware(argv[0]) < 0) {
                    cleanup_log_file();
                    return 1;
                }
                log_printf("🔧 FORCE CONTROLLER RESET MODE\n");
                log_printf("Current hardware status before reset:\n");
                print_hardware_status();
                log_printf("\nPerforming force controller reset...\n");
                force_controller_reset();
                log_printf("\nHardware status after reset:\n");
                print_hardware_status();
                cleanup_hardware();
                cleanup_log_file();
                return 0;
            case 'i':
                max_iterations = atoi(optarg);
                if (max_iterations < 1 || max_iterations > 31) {
                    fprintf(stderr, "Error: Invalid iterations: %d (must be 1-31)\n", max_iterations);
                    cleanup_log_file();
                    return 1;
                }
                log_printf("Setting MAX_ITERATIONS to %d\n", max_iterations);
                break;
            default:
                fprintf(stderr, "Usage: %s [-h] [-s] [-r] [-i N]\n", argv[0]);
                cleanup_log_file();
                return 1;
        }
    }
    
    /* Initialize hardware */
    if (initialize_hardware(argv[0]) < 0) {
        cleanup_log_file();
        return 1;
    }
    
    /* Reset hardware to ensure clean state after any previous interruptions */
    reset_hardware();
    usleep(500000);  /* Wait 500ms for hardware to stabilize */
    
    /* Run BER simulation */
    int result = run_ber_simulation();
    
    /* Cleanup */
    cleanup_hardware();
    cleanup_log_file();
    
    return result;
}

static int initialize_hardware(char *prog_name)
{
    /* Open /dev/mem */
    mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd < 0) {
        perror("Error opening /dev/mem");
        log_printf("Make sure to run as root: sudo %s\n", prog_name);
        return -1;
    }
    
    /* Map sim controller registers */
    sim_controller_regs = mmap(NULL, COMPONENT_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, 
                              mem_fd, SIM_CONTROLLER_BASE_ADDR);
    if (sim_controller_regs == MAP_FAILED) {
        perror("Error mapping sim controller registers");
        close(mem_fd);
        return -1;
    }
    
    /* Map BRAM */
    bram_base = mmap(NULL, COMPONENT_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, 
                     mem_fd, BRAM_BASE_ADDR);
    if (bram_base == MAP_FAILED) {
        perror("Error mapping BRAM");
        munmap((void*)sim_controller_regs, COMPONENT_SIZE);
        close(mem_fd);
        return -1;
    }
    
    log_printf("✅ Hardware mapping successful\n");
    log_printf("   Sim Controller: 0x%llX\n", SIM_CONTROLLER_BASE_ADDR);
    log_printf("   BRAM:          0x%llX\n", BRAM_BASE_ADDR);
    
    return 0;
}

static void cleanup_hardware(void)
{
    /* Stop any running simulations before cleanup */
    if (sim_controller_regs != NULL && sim_controller_regs != MAP_FAILED) {
        reset_hardware();
        munmap((void*)sim_controller_regs, COMPONENT_SIZE);
    }
    if (bram_base != NULL && bram_base != MAP_FAILED) {
        munmap((void*)bram_base, COMPONENT_SIZE);
    }
    if (mem_fd >= 0) {
        close(mem_fd);
    }
    
    sim_controller_regs = NULL;
    bram_base = NULL;
    mem_fd = -1;
}

static void signal_handler(int sig)
{
    static int signal_count = 0;
    signal_count++;
    
    log_printf("\n🛑 Received signal %d (count: %d), stopping simulation...\n", sig, signal_count);
    running = 0;
    
    /* stop hardware on first signal */
    if (sim_controller_regs != NULL) {
        force_controller_reset();
    }
    
    if (signal_count >= 2) {
        force_exit = 1;
        cleanup_hardware();
        cleanup_log_file();
        exit(1);
    }
}

static int run_ber_simulation(void)
{
    uint32_t ctrl_val;  /* Control register value with MAX_ITERATIONS */
    
    /* Reset and initialize simulation controller */
    write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, 0xFFFFFFFF);
    usleep(1000);
    
    for (int sim_no = 0; sim_no < MAX_SIMULATIONS && running; sim_no++) {
        log_printf("📈 Running simulation %d/%d\n", sim_no, MAX_SIMULATIONS);
        
        /* Stop any previous simulation first */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, CTRL_FULL_STOP_VALUE);
        usleep(10000);  /* 10ms delay */
        
        /* Clear BRAM counters for fresh simulation */
        clear_bram_counters();
        
        /* CRITICAL BER IP CONFIGURATION SEQUENCE */
        
        /* Step 1: Start configuration mode */
        log_printf("Configuring with MAX_ITERATIONS=%d for 2D RS decoder\n", max_iterations);
        ctrl_val = (max_iterations << 12) | 0x0000010F;  /* Build control value with dynamic MAX_ITERATIONS */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, ctrl_val);  /* Enable AXI interface with MAX_ITERATIONS */
        usleep(5000);
        
        /* Step 3: Load probability array WHILE RESET IS ASSERTED */
        load_probability_array(sim_no);
        
        /* Wait for simulation to run and process data */
        while (running && !force_exit) {
            usleep(100000);  /* 100ms delay */
            
            // get total bits, pre-fec bit errors, post-fec bit errors, total frames, total frame errors
            uint64_t total_bits = read_bram_64bit(BRAM_TOTAL_BITS_OFFSET);
            uint64_t total_bit_errors_pre = read_bram_64bit(BRAM_BIT_ERRORS_PRE_OFFSET);
            uint64_t total_bit_errors_post = read_bram_64bit(BRAM_BIT_ERRORS_POST_OFFSET);
            uint64_t total_frames = read_bram_64bit(BRAM_TOTAL_FRAMES_OFFSET);
            uint64_t total_frame_errors = read_bram_64bit(BRAM_FRAME_ERRORS_OFFSET);

            // if frame_errors > 1000 exit
            if (total_frame_errors >= 1000) {
                log_printf("   📍  Frame errors exceeded threshold (1000)\n");
                break;
            }
        }
        
        if (!running) break;

        /* Read and display results */
        print_ber_results(sim_no);
        
        /* Stop simulation */
        stop_simulation_hardware();
        
        usleep(100000);  /* Delay between simulations */
    }
    
    log_printf("✅ BER simulation completed\n");
    return 0;
}

static void load_probability_array(int sim_no)
{
    int start_idx = BLOCK_LENGTH * sim_no;
    
    /* Reset index register to prepare for loading */
    write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, 0xFFFFFFFF);
    usleep(1000);  /* small delay for hardware to recognize reset */
    
    /* Load probability values */
    for (int i = 0; i < BLOCK_LENGTH; i++) {
        uint64_t val = probability[start_idx + i];
        
        /* Write upper and lower 32 bits */
        write_sim_controller_reg(SIM_CTRL_REG2_OFFSET, (uint32_t)(val >> 32));
        write_sim_controller_reg(SIM_CTRL_REG3_OFFSET, (uint32_t)(val & 0xFFFFFFFF));
        
        /* Write index to trigger the loading */
        write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, (uint32_t)i);
        
        /* Small delay to ensure hardware processes the write */
        if (i % 16 == 15) {  /* Every 16 values */
            usleep(1000);  
        }
    }
    
    /* give BER IP time to process probabilities while reset is asserted */
    usleep(100000);  /* wait 100ms for probability processing */
    
    /* mark loading complete - this triggers START_REQ and releases reset */
    write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, 0xFFFFFFFF);
    
    /* allow time for reset release and BER IP initialization */
    usleep(50000);  /* wait 50ms for BER IP to start */
    
    /* ensure START bit is set in control register to actually start simulation */
    write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, (max_iterations << 12) | 0x0000010F);  /* Recalculate control value with MAX_ITERATIONS */
    usleep(10000);  /* Wait 10ms for start command to take effect */
    
    /* Verify the loading was accepted and START bit is set */
    uint32_t final_index = read_sim_controller_reg(SIM_CTRL_REG1_OFFSET);
    uint32_t final_control = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
    
    if (final_index == 0xFFFFFFFF && (final_control & CTRL_START_BIT)) {
        // successfully configured
    } else {
        log_printf("   ⚠️  BER IP reset sequence may have failed\n");
        if (!(final_control & CTRL_START_BIT)) {
            log_printf("      START bit not set in control register!\n");
        }
        if (final_index != 0xFFFFFFFF) {
            log_printf("      Index register not in expected state: 0x%08X\n", final_index);
        }
    }
}

static void print_ber_results(int sim_no)
{
    uint64_t total_bits = read_bram_64bit(BRAM_TOTAL_BITS_OFFSET);
    uint64_t total_bit_errors_pre = read_bram_64bit(BRAM_BIT_ERRORS_PRE_OFFSET);
    uint64_t total_bit_errors_post = read_bram_64bit(BRAM_BIT_ERRORS_POST_OFFSET);
    uint64_t total_frames = read_bram_64bit(BRAM_TOTAL_FRAMES_OFFSET);
    uint64_t total_frame_errors = read_bram_64bit(BRAM_FRAME_ERRORS_OFFSET);
    
    log_printf("📊 Simulation %d Results:\n", sim_no);
    log_printf("   Total Bits: %lu\n", total_bits);
    log_printf("   Bit Errors (Pre-FEC): %lu\n", total_bit_errors_pre);
    log_printf("   Bit Errors (Post-FEC): %lu\n", total_bit_errors_post);
    log_printf("   Total Frames: %lu\n", total_frames);
    log_printf("   Frame Errors: %lu\n", total_frame_errors);
    
    /* Sanity checks */
    if (total_bits == 0) {
        log_printf("   ⚠️  WARNING: No bits processed!\n");
        return;
    }
    
    if (total_bit_errors_pre > total_bits || total_bit_errors_post > total_bits) {
        log_printf("   ⚠️  WARNING: Error counts exceed total bits!\n");
        return;
    }
    
    if (total_frame_errors == 4294967296000ULL) {
        log_printf("   ⚠️  WARNING: Frame errors show possible overflow (2^32 * 1000)\n");
    }
    
    /* Calculate BER */
    if (total_bits > 0) {
        double ber_pre = (double)total_bit_errors_pre / total_bits;
        double ber_post = (double)total_bit_errors_post / total_bits;
        log_printf("   BER (Pre-FEC): %.2e\n", ber_pre);
        log_printf("   BER (Post-FEC): %.2e\n", ber_post);

        // calculate CER/frame error rate
        double cer = (double)total_frame_errors / total_frames;
        log_printf("   CER (Frame Error Rate): %.2e\n", cer);
            
        if (ber_post > 0 && ber_pre > ber_post) {
            log_printf("   Coding Gain: %.2f dB\n", 10.0 * log10(ber_pre / ber_post));
        } else {
            log_printf("   Coding Gain: N/A (invalid BER values)\n");
        }
    }
    
    log_printf("   SNR Analysis:\n");
    int start_idx = BLOCK_LENGTH * sim_no;
    const uint64_t *block_ptr = probability + start_idx;
    double snr_db = compute_snr_db(block_ptr);
    log_printf("   SNR for simulation %d: %.2f dB\n", sim_no, snr_db);
    
    /* CSV output for analysis */
    log_printf("CSV: %lu,%lu,%lu,%lu,%lu\n", 
           total_bits, total_bit_errors_pre, total_bit_errors_post, 
           total_frames, total_frame_errors);
}

static void write_sim_controller_reg(uint32_t offset, uint32_t value)
{
    sim_controller_regs[offset / 4] = value;
}

static uint32_t read_sim_controller_reg(uint32_t offset)
{
    return sim_controller_regs[offset / 4];
}

static uint64_t read_bram_64bit(uint32_t offset)
{
    uint32_t high = bram_base[offset / 4];
    uint32_t low = bram_base[(offset + 4) / 4];
    return ((uint64_t)high << 32) | low;
}

static int is_hardware_running(void)
{
    if (sim_controller_regs == NULL) {
        return 0;
    }
    
    uint32_t control_reg = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
    return (control_reg & CTRL_START_BIT) ? 1 : 0;
}

static void print_hardware_status(void)
{
    if (sim_controller_regs == NULL) {
        log_printf("⚠️  Hardware not mapped\n");
        return;
    }
    
    uint32_t ctrl_reg = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
    uint32_t idx_reg = read_sim_controller_reg(SIM_CTRL_REG1_OFFSET);
    
    log_printf("📊 Hardware Status:\n");
    log_printf("   Control register: 0x%08X ", ctrl_reg);
    if (ctrl_reg & CTRL_START_BIT) {
        log_printf("(RUNNING)\n");
    } else {
        log_printf("(STOPPED)\n");
    }
    log_printf("   Index register:   0x%08X\n", idx_reg);
    log_printf("   BRAM counters: bits=%u, frames=%u, frame_errors=%u\n",
           bram_base[0], bram_base[6], bram_base[8]);
}

static void stop_simulation_hardware(void)
{
    if (sim_controller_regs != NULL) {
        /* try graceful stop by clearing START bit only */
        uint32_t current_value = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
        log_printf("   Current control register: 0x%08X\n", current_value);
        
        /* clear START bit but keep other configuration */
        uint32_t stop_value = current_value & ~CTRL_START_BIT;
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, stop_value);
        usleep(10000);  /* wait 10ms */
        
        /* verify stop */
        uint32_t after_stop = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
        log_printf("   After graceful stop: 0x%08X\n", after_stop);
        
        /* if graceful stop didn't work, try forced stop */
        if (after_stop & CTRL_START_BIT) {
            log_printf("   Graceful stop failed, trying forced stop...\n");
            for (int i = 0; i < 5; i++) {
                write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, CTRL_FULL_STOP_VALUE);
                usleep(5000);  /* wait 5ms between attempts */
            }
            
            uint32_t after_force = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
            log_printf("   After forced stop: 0x%08X\n", after_force);
        }
    }
}

static void force_controller_reset(void)
{
    if (sim_controller_regs != NULL) {
        log_printf("🔧 FORCE CONTROLLER RESET: Using FSM stop_req mechanism...\n");
        
        /* read current state */
        uint32_t current_ctrl = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
        log_printf("   Current control register: 0x%08X\n", current_ctrl);
        
        /* state machine:
         * 1. Clear start_req (bit 0) 
         * 2. Assert stop_req to force FSM back to IDLE state
         * The stop_req signal is triggered when start_req goes low while BER is running
         */
        
        /* Step 1: Ensure we're in a running state first by setting start_req briefly */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, current_ctrl | 0x00000001);
        usleep(1000);  /* 1ms pulse */
        
        /* Step 2: Clear start_req to trigger stop_req in FSM - this forces IDLE state */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, current_ctrl & ~0x00000001);
        usleep(5000);  /* Wait 5ms for FSM transition */
        
        /* Step 3: Full stop to ensure clean state */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, 0x00000000);
        usleep(10000);  /* Wait 10ms */
        
        /* Step 4: Multiple rapid stop commands to break any stuck states */
        for (int i = 0; i < 10; i++) {
            write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, 0x00000000);
            usleep(1000);  /* 1ms between each stop command */
        }
        
        /* Step 5: final verification */
        uint32_t final_ctrl = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
        
        /* check if we successfully forced to idle state */
        if (final_ctrl == 0x00000000) {
            // Successfully reset
        } else {
            log_printf("⚠️  Force controller reset may have failed - register not zero\n");
        }
    }
}

static void reset_hardware(void)
{
    if (sim_controller_regs != NULL) {
        /* Step 1: Stop simulation first */
        stop_simulation_hardware();
        
        /* Step 2: Assert reset (bit 3 in control register) and disable enable */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, 0x00000008);  /* Set RESET bit only */
        usleep(50000);  /* Hold reset for 50ms */
        
        /* Step 3: Clear all registers while reset is asserted */
        for (int i = 0; i < 3; i++) {
            write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, 0x00000000);
            write_sim_controller_reg(SIM_CTRL_REG2_OFFSET, 0x00000000);
            write_sim_controller_reg(SIM_CTRL_REG3_OFFSET, 0x00000000);
            usleep(10000);  /* Wait 10ms between iterations */
        }
        
        /* Step 4: Release reset but keep disabled */
        write_sim_controller_reg(SIM_CTRL_REG0_OFFSET, CTRL_FULL_STOP_VALUE);
        usleep(100000);  /* Wait 100ms for reset recovery */
        
        /* Step 5: Initialize index register properly */
        write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, 0xFFFFFFFF);
        usleep(50000);  /* Wait 50ms */
        
        /* Step 6: Clear index register to ready state */
        write_sim_controller_reg(SIM_CTRL_REG1_OFFSET, 0x00000000);
        usleep(50000);  /* Wait 50ms */
        
        /* Step 7: Verify the reset by reading back control register */
        uint32_t control_reg = read_sim_controller_reg(SIM_CTRL_REG0_OFFSET);
        uint32_t index_reg = read_sim_controller_reg(SIM_CTRL_REG1_OFFSET);
        
        if (control_reg == 0x00000000 && index_reg == 0x00000000) {
            log_printf("✅ Hardware reset completed successfully\n");
        } else {
            log_printf("⚠️  Hardware reset may be incomplete\n");
            log_printf("   Control register: 0x%08X (expected: 0x00000000)\n", control_reg);
            log_printf("   Index register: 0x%08X (expected: 0x00000000)\n", index_reg);
        }
    }
}

static void clear_bram_counters(void)
{
    if (bram_base != NULL) {
        /* Clear all 64-bit counters in BRAM */
        /* Total bits counter (0x00-0x07) */
        bram_base[BRAM_TOTAL_BITS_OFFSET / 4] = 0;
        bram_base[(BRAM_TOTAL_BITS_OFFSET + 4) / 4] = 0;
        
        /* Pre-FEC bit errors counter (0x08-0x0F) */
        bram_base[BRAM_BIT_ERRORS_PRE_OFFSET / 4] = 0;
        bram_base[(BRAM_BIT_ERRORS_PRE_OFFSET + 4) / 4] = 0;
        
        /* Post-FEC bit errors counter (0x10-0x17) */
        bram_base[BRAM_BIT_ERRORS_POST_OFFSET / 4] = 0;
        bram_base[(BRAM_BIT_ERRORS_POST_OFFSET + 4) / 4] = 0;
        
        /* Total frames counter (0x18-0x1F) */
        bram_base[BRAM_TOTAL_FRAMES_OFFSET / 4] = 0;
        bram_base[(BRAM_TOTAL_FRAMES_OFFSET + 4) / 4] = 0;
        
        /* Frame errors counter (0x20-0x27) */
        bram_base[BRAM_FRAME_ERRORS_OFFSET / 4] = 0;
        bram_base[(BRAM_FRAME_ERRORS_OFFSET + 4) / 4] = 0;
        
        /* Small delay to ensure writes are completed */
        usleep(10000);  /* 10ms delay */
    }
}
