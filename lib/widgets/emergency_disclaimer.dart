import 'package:flutter/material.dart';

class EmergencyDisclaimer extends StatelessWidget {
  final String languageCode;

  const EmergencyDisclaimer({
    super.key,
    required this.languageCode,
  });

  String _getLocalizedDisclaimer() {
    final Map<String, String> disclaimers = {
      'en': 'This is not a substitute for professional medical advice. In case of emergency, call your local emergency services immediately.',
      'es': 'Esto no sustituye el consejo médico profesional. En caso de emergencia, llame inmediatamente a los servicios de emergencia locales.',
      'fr': 'Ceci ne remplace pas l\'avis médical professionnel. En cas d\'urgence, appelez immédiatement les services d\'urgence locaux.',
      'de': 'Dies ist kein Ersatz für professionelle medizinische Beratung. Im Notfall rufen Sie sofort den örtlichen Rettungsdienst an.',
      'it': 'Questo non sostituisce il parere medico professionale. In caso di emergenza, chiama immediatamente i servizi di emergenza locali.',
      'pt': 'Isto não substitui o aconselhamento médico profissional. Em caso de emergência, ligue imediatamente para os serviços de emergência locais.',
      'zh': '这不能替代专业的医疗建议。如遇紧急情况，请立即拨打当地急救服务电话。',
      'ja': 'これは専門医の診断に代わるものではありません。緊急の場合は、すぐに地域の救急サービスに電話してください。',
      'ko': '이것은 전문적인 의료 조언을 대체할 수 없습니다. 응급 상황의 경우 즉시 지역 응급 서비스에 전화하십시오.',
      'ru': 'Это не заменяет профессиональную медицинскую консультацию. В случае экстренной ситуации немедленно позвоните в местную службу экстренной помощи.',
      'ar': 'هذا ليس بديلاً عن المشورة الطبية المهنية. في حالة الطوارئ، اتصل بخدمات الطوارئ المحلية على الفور.',
      'hi': 'यह पेशेवर चिकित्सा सलाह का विकल्प नहीं है। आपातकालीन स्थिति में, तुरंत अपनी स्थानीय आपातकालीन सेवाओं को कॉल करें।',
    };

    return disclaimers[languageCode] ?? disclaimers['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
      child: Row(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              _getLocalizedDisclaimer(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12.0,
              ),
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
} 