import 'dart:io';

Future<void> main(List<String> arguments) async {
  final config = _TestConfig.fromArgs(arguments);

  if (Directory('coverage').existsSync()) {
    Directory('coverage').deleteSync(recursive: true);
  }

  final process = await Process.start(
    'flutter',
    [
      'test',
      '--coverage',
      '--test-randomize-ordering-seed=random',
      ...config.additionalFlutterArgs,
    ],
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('flutter test exited with $exitCode');
    exit(exitCode);
  }

  final coverageFile = File('coverage/lcov.info');
  if (!coverageFile.existsSync()) {
    stderr.writeln('Expected coverage report at coverage/lcov.info but none was found.');
    exit(1);
  }

  final summary = _CoverageSummary.parse(coverageFile.readAsLinesSync());
  stdout.writeln('Total coverage: ${summary.percent.toStringAsFixed(2)}% '
      '(${summary.linesHit}/${summary.linesFound} lines)');

  if (summary.percent + _doublePrecisionFix < config.minCoverage) {
    stderr.writeln('Coverage ${summary.percent.toStringAsFixed(2)}% fell below '
        'the required threshold of ${config.minCoverage.toStringAsFixed(2)}%.');
    exit(2);
  }
}

const double _doublePrecisionFix = 0.0001;

class _TestConfig {
  _TestConfig({
    required this.minCoverage,
    required this.additionalFlutterArgs,
  });

  factory _TestConfig.fromArgs(List<String> args) {
    double minCoverage = 70;
    final additionalArgs = <String>[];

    for (final arg in args) {
      if (arg.startsWith('--min-coverage=')) {
        final value = arg.split('=').last;
        final parsed = double.tryParse(value);
        if (parsed == null) {
          stderr.writeln('Could not parse --min-coverage value "$value".');
          exit(64);
        }
        minCoverage = parsed;
      } else if (arg == '--help' || arg == '-h') {
        _printHelp();
        exit(0);
      } else {
        additionalArgs.add(arg);
      }
    }

    return _TestConfig(
      minCoverage: minCoverage,
      additionalFlutterArgs: additionalArgs,
    );
  }

  final double minCoverage;
  final List<String> additionalFlutterArgs;
}

class _CoverageSummary {
  const _CoverageSummary({
    required this.linesFound,
    required this.linesHit,
  });

  factory _CoverageSummary.parse(List<String> lcovLines) {
    var found = 0;
    var hit = 0;

    for (final line in lcovLines) {
      if (line.startsWith('LF:')) {
        found += int.tryParse(line.substring(3)) ?? 0;
      } else if (line.startsWith('LH:')) {
        hit += int.tryParse(line.substring(3)) ?? 0;
      }
    }

    if (found == 0) {
      return const _CoverageSummary(linesFound: 0, linesHit: 0);
    }

    return _CoverageSummary(linesFound: found, linesHit: hit);
  }

  final int linesFound;
  final int linesHit;

  double get percent => linesFound == 0 ? 0 : (linesHit / linesFound) * 100;
}

void _printHelp() {
  const usage = 'Run flutter tests with coverage enforcement.\n\n'
      'Usage: dart run tool/test_with_coverage.dart [options]\n\n'
      'Options:\n'
      '  --min-coverage=<double>   Minimum coverage percentage required '
      '(default: 70)\n'
      '  -h, --help                Show this usage information\n\n'
      'Any additional arguments are forwarded to `flutter test` after the '
      'default flags.\n';
  stdout.write(usage);
}
