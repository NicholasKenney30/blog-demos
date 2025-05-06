import time
import numpy as np

def standard_method():
    result = []
    for i in range(1, 1000000):
        result.append(i * 2)
    return result

def vectorized_method():
    array = np.arange(1, 1000000)
    return array * 2

def benchmark():
    # Benchmark standard method
    start_time = time.time()
    standard_result = standard_method()
    standard_time = time.time() - start_time

    # Benchmark vectorized method
    start_time = time.time()
    vectorized_result = vectorized_method()
    vectorized_time = time.time() - start_time

    print(f"Standard method time: {standard_time:.6f} seconds")
    print(f"Vectorized method time: {vectorized_time:.6f} seconds")

if __name__ == "__main__":
    benchmark()