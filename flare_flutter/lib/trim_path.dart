library flare_flutter;

import 'dart:ui';

double _appendPathSegmentSequential(
    PathMetrics metrics, Path to, double offset, double start, double stop) {
  double nextOffset = offset;
  for (final PathMetric metric in metrics) {
    nextOffset = offset + metric.length;
    if (start < nextOffset) {
      Path extracted = metric.extractPath(start - offset, stop - offset);
      if (extracted != null) {
        to.addPath(extracted, Offset.zero);
      }
      if (stop < nextOffset) {
        break;
      }
    }
    offset = nextOffset;
  }
  return offset;
}

void _appendPathSegmentSync(
    PathMetric metric, Path to, double offset, double start, double stop) {
  double nextOffset = offset + metric.length;
  if (start < nextOffset) {
    Path extracted = metric.extractPath(start - offset, stop - offset);
    if (extracted != null) {
      to.addPath(extracted, Offset.zero);
    }
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

  if (complement) {
    if (trimStart > 0.0) {
      offset =
          _appendPathSegmentSequential(metrics, result, offset, 0.0, trimStart);
    }
    if (trimStop < totalLength) {
      offset = _appendPathSegmentSequential(
          metrics, result, offset, trimStop, totalLength);
    }
  } else {
    if (trimStart < trimStop) {
      offset = _appendPathSegmentSequential(
          metrics, result, offset, trimStart, trimStop);
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

Path trimPath(Path path, double startT, double stopT, bool complement,
    bool isSequential) {
  if (isSequential) {
    return _trimPathSequential(path, startT, stopT, complement);
  } else {
    return _trimPathSync(path, startT, stopT, complement);
  }
}
