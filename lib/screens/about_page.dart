import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('about_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Encabezado
            Text(
              'about_description'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Divider(),

            // 🔹 Profile
            _buildSection(
              context,
              title: 'about_profile_title'.tr(),
              items: [
                'about_profile_item1'.tr(),
                'about_profile_item2'.tr(),
                'about_profile_item3'.tr(),
              ],
            ),
            const Divider(),

            // 🔹 Cross-platform
            _buildSection(
              context,
              title: 'about_crossplatform_title'.tr(),
              items: [
                'about_crossplatform_item1'.tr(),
                'about_crossplatform_item2'.tr(),
              ],
            ),
            const Divider(),

            // 🔹 Multi-language
            _buildSection(
              context,
              title: 'about_multilang_title'.tr(),
              items: [
                'about_multilang_item1'.tr(),
                'about_multilang_item2'.tr(),
                'about_multilang_item3'.tr(),
                'about_multilang_item4'.tr(),
                'about_multilang_item5'.tr(),
                'about_multilang_item6'.tr(),
                'about_multilang_item7'.tr(),
                'about_multilang_item8'.tr(),
                'about_multilang_item9'.tr(),
                'about_multilang_item10'.tr(),
                'about_multilang_item11'.tr(),
                'about_multilang_item12'.tr(),
              ],
            ),
            const Divider(),

            // 🔹 Tabla de Roles estilizada
            Text('about_roles_title'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade300),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
              },
              children: [
                _buildRow([
                  'about_roles_module'.tr(),
                  'about_roles_functionality'.tr(),
                  'about_roles_manager'.tr(),
                  'about_roles_professor'.tr(),
                  'about_roles_student'.tr(),
                ], isHeader: true),
                _buildRow(['Profile', 'Manage profile', '✔️', '✔️', '✔️']),
                _buildRow(['Universities', 'Manage universities', '✔️', '', '']),
                _buildRow(['Professors', 'Manage professors', '✔️', '', '']),
                _buildRow(['Students', 'Manage students', '✔️', '✔️', '']),
                _buildRow(['', 'Register courses', '', '', '✔️']),
                _buildRow(['', 'Participate in course activities', '', '', '✔️']),
                _buildRow(['Courses', 'Manage courses', '✔️', '✔️', '']),
                _buildRow(['Activities', 'Manage activities', '✔️', '✔️', '']),
                _buildRow(['', 'View visual summaries and results', '✔️', '✔️', '']),
              ],
            ),
            const Divider(),

            // 🔹 Activities
            _buildSection(
              context,
              title: 'about_activities_title'.tr(),
              items: [
                'about_activities_item1'.tr(),
                'about_activities_item2'.tr(),
                'about_activities_item3'.tr(),
              ],
            ),
            const Divider(),

            // 🔹 AI Assistance
            _buildSection(
              context,
              title: 'about_ai_title'.tr(),
              items: [
                'about_ai_item1'.tr(),
                'about_ai_item2'.tr(),
                'about_ai_item3'.tr(),
                'about_ai_item4'.tr(),
              ],
            ),
            const Divider(),

            // 🔹 Imágenes de la app (Grid 2x3 con estilo)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1, // cuadrado
              children: const [
                _StyledImage('assets/images/learningprofile.png'),
                _StyledImage('assets/images/thesisreview.png'),
                _StyledImage('assets/images/feedback.png'),
                _StyledImage('assets/images/coursedetails.png'),
                _StyledImage('assets/images/studentactivities.png'),
                _StyledImage('assets/images/thesisreviewsummary.png'),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<String> items}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              )),
          const SizedBox(height: 8),
          Column(
            children: items
                .map((item) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(child: Text(item)),
              ],
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  TableRow _buildRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: isHeader
          ? const BoxDecoration(color: Colors.blueGrey)
          : null,
      children: cells
          .map((cell) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          cell,
          style: TextStyle(
            fontWeight:
            isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.white : Colors.black,
          ),
        ),
      ))
          .toList(),
    );
  }
}

// 🔹 Widget para aplicar estilo a cada imagen
class _StyledImage extends StatelessWidget {
  final String assetPath;

  const _StyledImage(this.assetPath, {super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // cuadrado
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain, // o BoxFit.cover si quieres que llene
        ),
      ),
    );
  }
}

