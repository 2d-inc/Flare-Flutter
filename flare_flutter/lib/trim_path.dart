import 'dart:ui';

double appendPathSegment(PathMetrics metrics, Path from, Path to, double offset,
    double start, double stop) {
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
  return nextOffset;
}

Path trimPath(Path path, double startT, double stopT, bool complement) {
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
      offset = appendPathSegment(metrics, path, result, offset, 0.0, trimStart);
    }
    if (trimStop < totalLength) {
      offset = appendPathSegment(
          metrics, path, result, offset, trimStop, totalLength);
    }
  } else {
    if (trimStart < trimStop) {
      offset =
          appendPathSegment(metrics, path, result, offset, trimStart, trimStop);
    }
  }

  return result;
}
