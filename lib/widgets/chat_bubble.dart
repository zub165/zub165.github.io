import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../models/agent_model.dart';
import '../services/agent_service.dart';
import 'agent_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showTranslation;
  final VoidCallback? onSpeakPressed;
  final bool isSpeaking;
  final String appearance;

  const ChatBubble({
    super.key,
    required this.message,
    this.showTranslation = false,
    this.onSpeakPressed,
    this.isSpeaking = false,
    this.appearance = 'nurse',
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final AgentService _agentService = AgentService();
  AgentAppearance? _agentAppearance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentAppearance();
    _setupAgentListener();
  }

  @override
  void dispose() {
    _disposeAgentListener();
    super.dispose();
  }

  Future<void> _setupAgentListener() async {
    // Listen for agent changes using SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.reload().then((_) {
      _loadAgentAppearance();
    });
  }

  Future<void> _disposeAgentListener() async {
    // Clean up any listeners if needed
  }

  Future<void> _loadAgentAppearance() async {
    final appearance = await _agentService.getCurrentAgent();
    if (mounted) {
      setState(() {
        _agentAppearance = appearance;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: widget.message.isUser ? TextDirection.rtl : TextDirection.ltr,
        children: [
          if (!widget.message.isUser) ...[
            _isLoading
                ? const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : AgentAvatar(
                    appearance: widget.appearance,
                    size: 36,
                  ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  widget.message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: widget.message.isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.text.contains('DIFFERENTIAL DIAGNOSIS')) ...[
                        ..._formatMedicalResponse(widget.message.text),
                      ] else ...[
                        Text(
                          widget.message.text,
                          style: TextStyle(
                            color: widget.message.isUser
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        // Add medical references section if it's an assistant message with SOURCES
                        if (!widget.message.isUser && widget.message.text.contains('SOURCES:'))
                          ..._buildMedicalReferences(),
                      ],
                      if (widget.showTranslation && widget.message.translatedText?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.translate,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Translation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.message.translatedText ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.message.hasAudio && widget.onSpeakPressed != null) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: widget.onSpeakPressed,
                    icon: Icon(
                      widget.isSpeaking ? Icons.stop : Icons.volume_up,
                      size: 20,
                      color: widget.isSpeaking 
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      widget.isSpeaking ? 'Stop' : 'Listen',
                      style: TextStyle(
                        color: widget.isSpeaking 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: (widget.isSpeaking 
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
                // Add medical references below the message for assistant messages
                if (!widget.message.isUser && !widget.message.text.contains('DIFFERENTIAL DIAGNOSIS') && !widget.message.text.contains('SOURCES:'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._buildMedicalReferences(),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _formatMedicalResponse(String text) {
    final sections = text.split('\n\n');
    final widgets = <Widget>[];
    
    for (final section in sections) {
      if (section.startsWith('DIFFERENTIAL DIAGNOSIS')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Differential Diagnosis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              ..._formatListItems(section),
            ],
          ),
        );
      } else if (section.startsWith('PATIENT SUMMARY')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Patient Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(section.replaceAll('PATIENT SUMMARY:', '').trim()),
            ],
          ),
        );
      } else if (section.startsWith('TREATMENT RECOMMENDATIONS')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Treatment Recommendations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              ..._formatListItems(section),
            ],
          ),
        );
      } else if (section.startsWith('EMERGENCY REFERRAL')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Emergency Referral',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(section.replaceAll('EMERGENCY REFERRAL:', '').trim()),
            ],
          ),
        );
      } else if (section.startsWith('IMPORTANT DISCLAIMER')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.replaceAll('IMPORTANT DISCLAIMER:', '').trim(),
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        );
      }
    }
    
    return widgets;
  }

  List<Widget> _formatListItems(String text) {
    final lines = text.split('\n');
    final items = <Widget>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith(RegExp(r'^\d+\.'))) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Text(line),
          ),
        );
      }
    }
    
    return items;
  }

  List<Widget> _buildMedicalReferences() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Medical References',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showMedicalReferences(context),
            icon: const Icon(Icons.medical_services_outlined, size: 16),
            label: const Text('Learn More'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Information based on reputable medical sources. Consult a healthcare professional for advice.',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      const SizedBox(height: 8),
      _buildSourceLink(
        'Centers for Disease Control and Prevention (CDC)',
        'https://www.cdc.gov/',
      ),
      _buildSourceLink(
        'World Health Organization (WHO)', 
        'https://www.who.int/',
      ),
    ];
  }
  
  Widget _buildSourceLink(String title, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  void _showMedicalReferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medical References',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                // Medical disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This information is provided for educational purposes only and is not a substitute for professional medical advice. Always consult with a qualified healthcare provider for diagnosis and treatment.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Official medical sources section
                Text(
                  'Official Medical Sources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildMedicalSourcesDetails(),
                const SizedBox(height: 24),
                // Additional resources section
                Text(
                  'Additional Resources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildAdditionalResourcesDetails(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildMedicalSourcesDetails() {
    final medicalSources = [
      {
        'title': 'Centers for Disease Control and Prevention (CDC)',
        'url': 'https://www.cdc.gov/',
        'description': 'The CDC is the leading national public health institute in the United States. It provides trusted health information on diseases, prevention strategies, and public health guidance.',
        'icon': Icons.health_and_safety,
      },
      {
        'title': 'World Health Organization (WHO)',
        'url': 'https://www.who.int/',
        'description': 'WHO is the United Nations agency that connects nations, partners and people to promote health, keep the world safe and serve the vulnerable – so everyone, everywhere can attain the highest level of health.',
        'icon': Icons.public,
      },
      {
        'title': 'National Institutes of Health (NIH)',
        'url': 'https://www.nih.gov/',
        'description': 'NIH is the primary agency of the United States government responsible for biomedical and public health research. It conducts its own research and provides funding for research worldwide.',
        'icon': Icons.science,
      },
      {
        'title': 'Mayo Clinic',
        'url': 'https://www.mayoclinic.org/',
        'description': 'Mayo Clinic is a nonprofit organization committed to clinical practice, education and research, providing expert, whole-person care to everyone who needs healing.',
        'icon': Icons.local_hospital,
      },
    ];
    
    return medicalSources.map((source) => _buildDetailedSourceItem(
      source['title'] as String,
      source['url'] as String,
      source['description'] as String,
      source['icon'] as IconData,
    )).toList();
  }
  
  List<Widget> _buildAdditionalResourcesDetails() {
    final additionalResources = [
      {
        'title': 'MedlinePlus',
        'url': 'https://medlineplus.gov/',
        'description': 'MedlinePlus is an online health information resource for patients and their families and friends. It offers reliable, up-to-date health information about diseases, conditions, and wellness issues.',
        'icon': Icons.library_books,
      },
      {
        'title': 'Cleveland Clinic',
        'url': 'https://my.clevelandclinic.org/',
        'description': 'Cleveland Clinic is a nonprofit multispecialty academic medical center that integrates clinical and hospital care with research and education.',
        'icon': Icons.medical_services,
      },
      {
        'title': 'Johns Hopkins Medicine',
        'url': 'https://www.hopkinsmedicine.org/',
        'description': 'Johns Hopkins Medicine, based in Baltimore, Maryland, is an integrated global health enterprise and one of the leading health care systems in the United States.',
        'icon': Icons.healing,
      },
    ];
    
    return additionalResources.map((source) => _buildDetailedSourceItem(
      source['title'] as String,
      source['url'] as String,
      source['description'] as String,
      source['icon'] as IconData,
    )).toList();
  }
  
  Widget _buildDetailedSourceItem(String title, String url, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launchURL(url),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Visit Website'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }
} 