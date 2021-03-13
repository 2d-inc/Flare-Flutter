import 'dart:ui';

Path trimPath(Path path, double startT, double stopT, bool complement,
    bool isSequential) {
  if (isSequential) {
    return _trimPathSequential(path, startT, stopT, complement);
  } else {
    return _trimPathSync(path, startT, stopT, complement);
  }
}

double _appendPathSegmentSequential(Iterator<PathMetric> metricsIterator,
    Path to, double offset, double start, double stop) {
  double nextOffset = offset;
  do {
    PathMetric metric = metricsIterator.current;
    nextOffset = offset + metric.length;
    if (start < nextOffset) {
      Path extracted = metric.extractPath(start - offset, stop - offset);

      to.addPath(extracted, Offset.zero);

      if (stop < nextOffset) {
        break;
      }
    }
    // ignore: parameter_assignments
    offset = nextOffset;
  } while (metricsIterator.moveNext());
  return offset;
}

void _appendPathSegmentSync(
    PathMetric metric, Path to, double offset, double start, double stop) {
  double nextOffset = offset + metric.length;
  if (start < nextOffset) {
    Path extracted = metric.extractPath(start - offset, stop - offset);
    to.addPath(extracted, Offset.zero);
  }
}

Path _trimPathSequential(
    Path path, double startT, double stopT, bool complement) {
  final Path result = Path();

  // Measure length of all the contours.
  PathMetrics metrics = path.computeMetrics();
  double totalLength = 0.0;
  for (final PathMetric metric in metrics) {
    totalLength += metric.length;
  }

  // Reset metrics from the start.
  metrics = path.computeMetrics();
  double trimStart = totalLength * startT;
  double trimStop = totalLength * stopT;
  double offset = 0.0;

  Iterator<PathMetric> metricsIterator = metrics.iterator;
  metricsIterator.moveNext();
  if (complement) {
    if (trimStart > 0.0) {
      offset = _appendPathSegmentSequential(
          metricsIterator, result, offset, 0.0, trimStart);
    }
    if (trimStop < totalLength) {
      offset = _appendPathSegmentSequential(
          metricsIterator, result, offset, trimStop, totalLength);
    }
  } else {
    if (trimStart < trimStop) {
      offset = _appendPathSegmentSequential(
          metricsIterator, result, offset, trimStart, trimStop);
    }
  }

  return result;
}

Path _trimPathSync(Path path, double startT, double stopT, bool complement) {
  final Path result = Path();

  final PathMetrics metrics = path.computeMetrics();
  for (final PathMetric metric in metrics) {
    double length = metric.length;
    double trimStart = length * startT;
    double trimStop = length * stopT;

    if (complement) {
      if (trimStart > 0.0) {
        _appendPathSegmentSync(metric, result, 0.0, 0.0, trimStart);
      }
      if (trimStop < length) {
        _appendPathSegmentSync(metric, result, 0.0, trimStop, length);
      }
    } else {
      if (trimStart < trimStop) {
        _appendPathSegmentSync(metric, result, 0.0, trimStart, trimStop);
      }
    }
  }
  return result;
}
