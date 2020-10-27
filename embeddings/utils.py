import logging
import numpy as np
from tqdm import tqdm
from multiprocessing import cpu_count
from concurrent.futures import ProcessPoolExecutor, as_completed


def initialise_logger(log_level, name):
    logger = logging.getLogger(name)
    log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=log_level, format=log_fmt)
    return logger


def multicore_apply(array, func, n_jobs=cpu_count()-1, use_kwargs=False, front_num=0):
    """
        A parallel version of the map func with a progress bar.
        Args:
            array (array-like): An array to iterate over.
            func (func): A python func to apply to the elements of array
            n_jobs (int, default=16): The number of cores to use
            use_kwargs (boolean, default=False): Whether to consider the elements of array as dictionaries of
                keyword arguments to func
            front_num (int, default=3): The number of iterations to run serially before kicking off the parallel job.
                Useful for catching bugs
        Returns:
            [func(array[0]), func(array[1]), ...]
    """

    array = list(array)

    #We run the first few iterations serially to catch bugs
    front = []
    if front_num > 0:
        front = [func(**a) if use_kwargs else func(a) for a in array[:front_num]]
    #If we set n_jobs to 1, just run a list comprehension. This is useful for benchmarking and debugging.
    if n_jobs==1:
        return front + [func(**a) if use_kwargs else func(a) for a in tqdm(array[front_num:])]
    #Assemble the workers
    with ProcessPoolExecutor(max_workers=n_jobs) as pool:
        #Pass the elements of array into func
        if use_kwargs:
            futures = [pool.submit(func, **a) for a in array[front_num:]]
        else:
            futures = [pool.submit(func, a) for a in array[front_num:]]
        kwargs = {
            'total': len(futures),
            'unit': 'it',
            'unit_scale': True,
            'leave': True
        }
        #Print out the progress as tasks complete
        for f in tqdm(as_completed(futures), **kwargs):
            pass
    out = []
    #Get the results from the futures.
    for i, future in tqdm(enumerate(futures)):
        try:
            out.append(future.result())
        except Exception as e:
            out.append(e)
    return front + out


def calculate_distance_matrix(A,B):
    p1 = np.sum(A**2, axis=1)[:, np.newaxis]
    p2 = np.sum(B**2, axis=1)
    p3 = -2 * np.dot(A, B.T)
    res = p1 + p2 + p3
    res[res<0] = 0
    res = np.sqrt(res)
    return res
