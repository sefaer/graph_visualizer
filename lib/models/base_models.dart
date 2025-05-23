abstract class BaseVisualizationStep {
  final String description;
  final int currentStep;
  final int totalSteps;

  BaseVisualizationStep({
    required this.description,
    required this.currentStep,
    required this.totalSteps,
  });
}