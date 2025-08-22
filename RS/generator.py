
def data_in(r=32):
    # yield a number from 0-2^5-1, so 0-31 a upcounter
    while True:
        for i in range(r):
            yield i

# test
if __name__ == "__main__":
    for i in data_in():
        print(i)