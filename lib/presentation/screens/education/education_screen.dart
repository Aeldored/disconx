import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/education_content_model.dart';
import 'widgets/security_tip_card.dart';
import 'widgets/learning_module_card.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final List<SecurityTip> _securityTips = [
    SecurityTip(
      id: '1',
      title: 'Always Use VPN',
      description: 'When on public Wi-Fi',
      icon: Icons.lock,
      backgroundColor: Colors.blue[100]!,
    ),
    SecurityTip(
      id: '2',
      title: 'Verify Networks',
      description: 'Check before connecting',
      icon: Icons.shield,
      backgroundColor: Colors.green[100]!,
    ),
    SecurityTip(
      id: '3',
      title: 'Strong Passwords',
      description: 'For your Wi-Fi networks',
      icon: Icons.key,
      backgroundColor: Colors.purple[100]!,
    ),
    SecurityTip(
      id: '4',
      title: 'Stay Updated',
      description: 'On security threats',
      icon: Icons.notifications_active,
      backgroundColor: Colors.yellow[100]!,
    ),
  ];

  final List<EducationContentModel> _learningModules = [
    EducationContentModel(
      id: '1',
      title: 'Understanding Evil Twin Attacks',
      description: 'Learn how attackers create fake Wi-Fi networks and how to spot them',
      type: ContentType.article,
      difficulty: DifficultyLevel.beginner,
      estimatedMinutes: 5,
      imageUrl: 'assets/images/image2.png',
      tags: ['security', 'evil-twin', 'wi-fi'],
      viewCount: 1200,
      publishedDate: DateTime.now().subtract(const Duration(days: 7)),
    ),
    EducationContentModel(
      id: '2',
      title: 'Public Wi-Fi Safety Guide',
      description: 'Essential tips for staying safe when using public Wi-Fi networks',
      type: ContentType.article,
      difficulty: DifficultyLevel.beginner,
      estimatedMinutes: 8,
      imageUrl: 'assets/images/image1.png',
      tags: ['safety', 'public-wifi', 'tips'],
      viewCount: 856,
      publishedDate: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  final List<EducationContentModel> _quizzes = [
    EducationContentModel(
      id: '3',
      title: 'Wi-Fi Security Quiz',
      description: 'Test your knowledge about Wi-Fi security best practices',
      type: ContentType.quiz,
      difficulty: DifficultyLevel.intermediate,
      estimatedMinutes: 10,
      tags: ['quiz', 'security', 'test'],
      viewCount: 543,
      publishedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cybersecurity Education',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learn how to protect yourself from Wi-Fi security threats',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Tips Section
                const Text(
                  'Security Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _securityTips.length,
                  itemBuilder: (context, index) {
                    return SecurityTipCard(tip: _securityTips[index]);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Learning Modules Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Learning Modules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_learningModules.map((module) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LearningModuleCard(
                    module: module,
                    onStart: () => _startModule(module),
                  ),
                ))),
                
                const SizedBox(height: 24),
                
                // Test Your Knowledge Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Test Your Knowledge',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Quiz Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _quizzes.first.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _quizzes.first.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.quiz,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '10 questions',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: AppColors.success,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Get certified',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _startQuiz(_quizzes.first),
                            child: const Text('Start Quiz'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Additional Resources
                const Text(
                  'Additional Resources',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildResourceLink(
                  icon: Icons.link,
                  title: 'DICT Cybersecurity Portal',
                  subtitle: 'Official government resources',
                  onTap: () {},
                ),
                _buildResourceLink(
                  icon: Icons.video_library,
                  title: 'Video Tutorials',
                  subtitle: 'Watch step-by-step guides',
                  onTap: () {},
                ),
                _buildResourceLink(
                  icon: Icons.download,
                  title: 'Download Security Checklist',
                  subtitle: 'PDF guide for offline reference',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceLink({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _startModule(EducationContentModel module) {
    // TODO: Navigate to module content viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting: ${module.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _startQuiz(EducationContentModel quiz) {
    // TODO: Navigate to quiz screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting quiz: ${quiz.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}