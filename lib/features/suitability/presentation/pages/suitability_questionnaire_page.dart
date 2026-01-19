import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/suitability_models.dart';
import '../controllers/suitability_controller.dart';

class SuitabilityQuestionnairePage extends StatefulWidget {
  const SuitabilityQuestionnairePage({super.key});

  @override
  State<SuitabilityQuestionnairePage> createState() => _SuitabilityQuestionnairePageState();
}

class _SuitabilityQuestionnairePageState extends State<SuitabilityQuestionnairePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SuitabilityController>().loadQuestionnaire();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar Suitability'),
      ),
      body: Consumer<SuitabilityController>(
        builder: (context, controller, _) {
          if (controller.isQuestionnaireLoading && controller.questionnaire == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final questionnaire = controller.questionnaire;
          if (questionnaire == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage ?? 'Não foi possível carregar o questionário.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.isQuestionnaireLoading ? null : controller.loadQuestionnaire,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final sections = {for (final section in questionnaire.sections) section.id: section};
          final widgets = <Widget>[];

          for (final question in questionnaire.questions) {
            final section = question.sectionId != null ? sections[question.sectionId!] : null;
            if (section != null) {
              widgets.add(Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ));
            }

            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.prompt,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (question.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            question.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (question.required) ...[
                          const SizedBox(height: 8),
                          const Chip(label: Text('Obrigatória')),
                        ],
                        const SizedBox(height: 8),
                        ...question.options.map(
                          (option) => RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: option.id,
                            groupValue: controller.selectedOptions[question.id],
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectOption(question.id, value);
                              }
                            },
                            title: Text(option.label),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.loadQuestionnaire,
                  child: ListView(
                    children: widgets,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: !controller.canSubmit || controller.isSubmitting
                        ? null
                        : () async {
                            final succeeded = await controller.submitAnswers();
                            if (!mounted) return;
                            if (succeeded) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Suitability atualizado com sucesso!')),
                                );
                              }
                              Navigator.of(context).pop();
                            } else if (controller.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(controller.errorMessage!)),
                              );
                            }
                          },
                    child: controller.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar respostas'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
