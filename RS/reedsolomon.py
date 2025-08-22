import reedsolo, random, math

DEBUG = True

def print_square_matrix(matrix):
    """
    Print a square matrix in a square

    :param matrix: The square matrix to print.
    """
    if DEBUG:
        for row in matrix:
            print(" ".join(f"{elem:3}" for elem in row))
        print()

def rotate_matrix(matrix, direction):
    """
    Rotate a square matrix 90 degrees in the specified direction.

    :param matrix: The square matrix to rotate (list of lists).
    :param direction: 'cw' for clockwise or 'ccw' for counter-clockwise.
    :return: The rotated matrix.
    """
    if direction == 'cw':
        # transpose and then reverse each row
        return [list(reversed(col)) for col in zip(*matrix)]
    elif direction == 'ccw':
        # reverse each row, then transpose
        return list(map(list, zip(*matrix)))[::-1]
    else:
        raise ValueError("Direction must be 'cw' or 'ccw'.")

class ReedSolomon1D():
    def __init__(self, n, k):
        """
        Initialize the Reed-Solomon codec with given parameters.

        :param n: The total number of symbols in the codeword.
        :param k: The number of data symbols.
        """
        self.rs = reedsolo.RSCodec(n - k, c_exp=16)

    def encode(self, data, n, k):
        """
        Encode data using Reed-Solomon encoding.

        :param data: The input data to encode (as bytes).
        :param n: The total number of symbols in the codeword.
        :param k: The number of data symbols.
        :return: The encoded data as bytes.
        """

        return self.rs.encode(data)

    def decode(self, data, n, k):
        """
        Decode data using Reed-Solomon decoding.

        :param data: The encoded data to decode (as bytes).
        :param n: The total number of symbols in the codeword.
        :param k: The number of data symbols.
        :return: The decoded data as bytes.
        """
        try:
            return self.rs.decode(data)[0]
        except reedsolo.ReedSolomonError as e:
            # print(f"Decoding error: {e}")
            return None

class ReedSolomon2D():
    def __init__(self, n, k):
        """
        Initialize the Reed-Solomon codec with given parameters.

        :param n: The total number of symbols in the codeword.
        :param k: The number of data symbols.
        """
        self.rs = reedsolo.RSCodec(n - k, c_exp=16)

    def encode(self, data, n, k):
        """
        Encode data using Reed-Solomon encoding.

        :param data: The input data to encode (as bytes) - as flattenned.
        :param n: The total number of symbols in the codeword.
        :param k: The number of data symbols.
        :return: The encoded data as bytes.
        """
        # unflatten the data into a 2D array
        data = [list(data[i:i + k]) for i in range(0, len(data), k)]

        # get the 2d array size
        parity_size = n - k
        rows = len(data)
        cols = len(data[0]) if rows > 0 else 0
        arr_size = (rows + parity_size) * (cols + parity_size)

        arr = [ [0] * (cols + parity_size) for _ in range(rows + parity_size) ]

        # populate the array with data
        for i in range(rows):
            # encode the row
            row_data = data[i]
            encoded_row = self.rs.encode(row_data)

            for j in range(len(encoded_row)):
                try:
                    arr[i][j] = encoded_row[j]
                except IndexError as e:
                    print(f"IndexError: {e} - arr size: {len(arr)}, i: {i}, j: {j}, encoded_row size: {len(encoded_row)}")
                    raise

        # encode the columns
        for j in range(cols):
            col_data = [arr[i][j] for i in range(rows)]
            encoded_col = self.rs.encode(col_data)

            for r in range(rows, rows + parity_size):
                arr[r][j] = encoded_col[r]

        # parity on parity!
        # do by row
        parity_parity_rows = [[0] * (cols + parity_size) for _ in range(parity_size)]
        for i in range(rows, rows + parity_size):
            # encode the row
            row_data = arr[i][:cols]
            encoded_row = self.rs.encode(row_data)

            for j in range(len(encoded_row)):
                parity_parity_rows[i - rows][j] = encoded_row[j]
        
        # do by col
        parity_parity_cols = [[0] * (parity_size) for _ in range(rows + parity_size)]
        for j in range(cols, cols + parity_size):
            col_data = [arr[i][j] for i in range(rows + parity_size)][:cols]
            encoded_col = self.rs.encode(col_data)
            for r in range(len(encoded_col)):
                parity_parity_cols[r][j - cols] = encoded_col[r]

        # they should be the same!! - rules
        # extra parity symbols from rows
        ppr = [row[rows:] for row in parity_parity_rows]  # take only the parity part

        # extra parity symbols from cols
        ppc = parity_parity_cols[cols:]

        # if same, add to arr - compared ppr and ppc
        if ppr == ppc:
            for i in range(parity_size):
                for j in range(parity_size):
                    arr[rows + i][cols + j] = ppr[i][j]
        else:
            print("Warning: Parity rows and columns do not match!")

        # print_square_matrix(arr)

        return sum(arr, [])  # flatten the 2D array to 1D bytes

    def decode(self, data, n, k, max_iterations=math.inf):
        """
        Decode data using Reed-Solomon decoding.

        :param data: The encoded data to decode (as bytes) - flattened.
        :param n: The total number of symbols in the codeword.
        :param k: The number of data symbols.
        :return: The decoded data as bytes.
        """
        # reconstruct 2D array into nxn
        arr = [data[i:i + n] for i in range(0, len(data), n)]
        rows = len(arr)
        cols = len(arr[0]) if rows > 0 else 0
        parity_size = n - k

        if rows != cols or rows != n or cols != n:
            raise ValueError("Data does not match expected dimensions for Reed-Solomon 2D decoding.")
        
        # decode rows 
        """
         - decode each row (keep track of how many symbols changed, if none at the end of cols iterations, break)
         - rotate the matrix ccw - then do decode on each row (which would be the original columns)
         - if changes made, keep going, if no changes made in all of decode of rows and cols, break
        
        1 2 X -
        3 4 X -
        X X X -

        ccw

        X X X
        2 4 X
        1 3 X

        cw

        reset!
        """

        iterations = 0
        while iterations < max_iterations:
            iterations += 1
            changes = 0

            for direction in ['ccw', 'cw']:
                # decode each row
                for i in range(rows):
                    row_data = arr[i]

                    try:
                        decoded_row = self.rs.decode(row_data)
                        if decoded_row is not None:
                            decoded_row = decoded_row[1]
                            arr[i] = list(decoded_row)
                            # print(f"Decoded row {i}: {arr[i]}")
                            changes += sum(1 for j in range(cols) if arr[i][j] != row_data[j])
                    except reedsolo.ReedSolomonError as e:
                        # print(f"Row decoding error: {e} - {list(row_data)}")
                        arr[i] = list(row_data)  # keep original row if decoding fails

                arr = rotate_matrix(arr, direction)

            if changes == 0:
                print(f"No changes made in iteration {iterations}, stopping decoding.")
                break

        print(f"iterations: {iterations}")

        # remove parity symbols
        arr = [row[:cols - parity_size] for row in arr[:rows - parity_size]]

        return sum(arr, [])

# Example usage:
if __name__ == "__main__":
    n = 5  # Total number of symbols in the codeword
    k = 3  # Number of data symbols

    # # each symbol, we say is 1 byte, so we can encode 11 bytes of data (0-255)

    # data = [random.randint(0, 255) for _ in range(k)]

    # print(f"Original data: {data}")

    # Initialize RS codec with 4 parity symbols (n=15, k=11 ⇒ nsym=4)
    # rs = ReedSolomon1D(n, k)
    rs = ReedSolomon2D(n, k)

    data = [[random.randint(0, 255) for _ in range(k)] for _ in range(k)]
    print(f"Original data: {data}")
    data = bytes(sum(data, []))  # flatten the 2D array to 1D bytes

    encoded_data = rs.encode(data, n, k)
    # print(f"Encoded data: {encoded_data}")
    # print(f"Encoded data list: {list(encoded_data)}")

    # # simulate some errors in the encoded data
    error_indices = random.sample(range(len(encoded_data)), 3)  # Randomly choose 3 indices to corrupt
    corrupted_data = bytearray(encoded_data)
    for index in error_indices:
        corrupted_data[index] = random.randint(0, 255)  # Introduce random errors
    # print(f"Corrupted data: {corrupted_data}")
    # corrupted_data = bytearray(encoded_data)    # temp
    decoded_data = rs.decode(corrupted_data, n, k)#[0]
    if decoded_data is not None:
        print(f"Original data:\t {list(data)}")
        corrupted_data_no_parity = [list(corrupted_data[:k]) for _ in range(k)]
        print(f"Corrupted data:\t {list(sum(corrupted_data_no_parity, []))}")
        print(f"Decoded data:\t {list(decoded_data)}")
    else:
        print("Decoding failed.")

    # assert data == list(decoded_data), "Decoded data does not match original data!"

