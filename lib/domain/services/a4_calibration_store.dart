abstract class A4CalibrationStore {
  Future<double?> readA4Hz();

  Future<void> writeA4Hz(double a4Hz);
}
