slide_period_common <- function(x,
                                i,
                                period,
                                f_call,
                                every,
                                origin,
                                before,
                                after,
                                complete,
                                ptype,
                                constrain,
                                atomic,
                                env,
                                type) {
  check_index_incompatible_type(i, ".i")
  check_index_cannot_be_na(i, ".i")
  check_index_must_be_ascending(i, ".i")

  before_unbounded <- is_unbounded(before)
  after_unbounded <- is_unbounded(after)

  before <- check_slide_period_before(before, before_unbounded)
  after <- check_slide_period_after(after, after_unbounded)
  complete <- check_slide_period_complete(complete)

  groups <- warp_distance(
    i,
    period = period,
    every = every,
    origin = origin
  )

  unique <- unique(groups)

  starts <- unique - before
  stops <- unique + after

  if (complete) {
    n <- length(unique)
    first <- unique[[1]]
    last <- unique[[n]]

    from <- compute_from(starts, first, n, before_unbounded)
    to <- compute_to(stops, last, n, after_unbounded)

    # Only slice if we have to
    # Important to use seq2()! Could have `from > to`
    if (from != 1L || to != n) {
      starts <- starts[seq2(from, to)]
      stops <- stops[seq2(from, to)]
    }
  }

  out <- hop_index_common(
    x = x,
    i = groups,
    starts = starts,
    stops = stops,
    f_call = f_call,
    ptype = ptype,
    constrain = constrain,
    atomic = atomic,
    env = env,
    type = type
  )

  if (!complete) {
    return(out)
  }

  # Pad with ptype
  init <- vec_init(ptype, n = 1L)

  front <- vec_recycle(init, from - 1L)
  back <- vec_recycle(init, n - to)

  out <- vec_c(front, out, back)

  out
}

compute_from <- function(starts, first, n, before_unbounded) {
  .Call(slider_compute_from, starts, first, n, before_unbounded)
}

compute_to <- function(stops, last, n, after_unbounded) {
  .Call(slider_compute_to, stops, last, n, after_unbounded)
}

check_slide_period_before <- function(x, unbounded) {
  vec_assert(x, size = 1L, arg = ".before")

  if (unbounded) {
    return(x)
  }

  x <- vec_cast(x, integer(), x_arg = ".before")

  if (is.na(x)) {
    abort("`.before` cannot be `NA`.")
  }

  x
}

check_slide_period_after <- function(x, unbounded) {
  vec_assert(x, size = 1L, arg = ".after")

  if (unbounded) {
    return(x)
  }

  x <- vec_cast(x, integer(), x_arg = ".after")

  if (is.na(x)) {
    abort("`.after` cannot be `NA`.")
  }

  x
}

check_slide_period_complete <- function(x) {
  vec_assert(x, size = 1L, arg = ".complete")

  x <- vec_cast(x, logical(), x_arg = ".complete")

  if (is.na(x)) {
    abort("`.complete` cannot be `NA`.")
  }

  x
}
