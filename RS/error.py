import random

# if MODE == "1D":
#     global_index = N * current_index + i
# elif MODE == "2D":
#     global_index = N * N * current_index + i

class ErrorHelpers():

    def __init__(self, e, MODE="1D", N=255, N_ERR=10):
        self.e = e          # error model
        self.MODE = MODE
        self.N = N
        self.N_ERR = N_ERR

    @staticmethod
    def inject_error(value):
        # add 1 if possible, otherwise subtract 1
        if value >= 0:
            return value - 1
        else:
            return value + 1
    
    def inject_errors(self, encoded_data, method="random"):
        """
        Inject errors into the encoded data.
        :param encoded_data: The encoded data to inject errors into.
        :param method: The method to inject errors. "random" or "burst".
        :param MODE: The mode of operation, either "1D" or "2D".
        :param N: The number of symbols in the encoded data.
        :param N_ERR: The number of errors to inject.
        :return: The encoded data with errors injected.
        """
        mult = 1 if self.MODE == "1D" else self.N # for 2D, we have N^2 symbols

        if method == "random":
            for _ in range(self.N_ERR * mult):
                idx = random.randint(0, self.N * mult - 1)
                # introduce an error by flipping a bit
                encoded_data[idx] ^= 1 << random.randint(0, 7)
            # if MODE == "1D":
            #     encoded_data = bytes(encoded_data)
            # elif MODE == "2D":
            encoded_data = encoded_data
        elif method == "burst":
            encoded_data = self.e.inject(encoded_data)
            
        return encoded_data

class BurstError():
    def __init__(self, iep, epf):
        self.error = 0  # error (0 - prev state no error, 1 - prev state error)
        self.iep = iep      # initial error probability
        self.epf = epf      # error propagation factor

        self.injected_errors = 0  # count of injected errors

    def inject(self, data):
        data = data[:]

        # loop through each data symbol
        for i in range(len(data)):
            # determine if an error should be injected
            rv_1 = random.random()
            rv_2 = random.random()

            inject_error = (
                self.error == 0 and rv_1 < self.iep
            ) or (
                self.error == 1 and rv_2 < self.epf
            )

            if inject_error:
                self.error = 1
                self.injected_errors += 1
                # inject an error by flipping a bit
                data[i] = ErrorHelpers.inject_error(data[i])
            else:
                self.error = 0

        print(f"Injected {self.injected_errors} errors into the data.")
        return data
    
    def reset(self):
        """Reset the error state."""
        self.error = 0
        return self
    
if __name__ == "__main__":
    # Example usage
    be = BurstError(iep=0.1, epf=0.3)
    data = [0] * 100
    data_with_errors = be.inject(data)

    print("Original data:\t\t", data)
    print("Data with errors:\t", data_with_errors)
