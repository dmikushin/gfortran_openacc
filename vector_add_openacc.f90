program vector_add_test
    implicit none

    integer, parameter :: N = 10000000
    integer, parameter :: NUM_ITERATIONS = 100
    real, dimension(:), allocatable :: a, b, c
    integer :: i, iter
    real :: start_time, end_time, total_time

    ! Allocate arrays dynamically
    allocate(a(N))
    allocate(b(N))
    allocate(c(N))

    ! Initialize vectors
    do i = 1, N
        a(i) = real(i)
        b(i) = real(2 * i)
    end do

    print *, "Starting OpenACC vector addition test..."
    print *, "Vector size: ", N
    print *, "Number of iterations: ", NUM_ITERATIONS

    ! GPU computation using OpenACC with multiple iterations
    call cpu_time(start_time)

    do iter = 1, NUM_ITERATIONS
        !$acc parallel loop copyin(a, b) copyout(c)
        do i = 1, N
            c(i) = a(i) + b(i)
        end do
        !$acc end parallel loop
    end do

    call cpu_time(end_time)
    total_time = end_time - start_time

    ! Verification
    print *, "First 5 results:"
    do i = 1, 5
        print *, "c(", i, ") = ", c(i), " (expected: ", real(3*i), ")"
    end do

    print *, "Last 5 results:"
    do i = N-4, N
        print *, "c(", i, ") = ", c(i), " (expected: ", real(3*i), ")"
    end do

    print *, "Total GPU time: ", total_time, " seconds"
    print *, "Average time per iteration: ", total_time / NUM_ITERATIONS, " seconds"

    ! Verify correctness
    do i = 1, N
        if (abs(c(i) - real(3*i)) > 1e-6) then
            print *, "ERROR: Result mismatch at index ", i
            stop 1
        end if
    end do

    print *, "Test PASSED: All results are correct!"

    ! Deallocate arrays
    deallocate(a)
    deallocate(b)
    deallocate(c)

end program vector_add_test
