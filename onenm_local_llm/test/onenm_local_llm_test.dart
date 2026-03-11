import 'package:flutter_test/flutter_test.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';
import 'package:onenm_local_llm/onenm_local_llm_platform_interface.dart';
import 'package:onenm_local_llm/onenm_local_llm_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOnenmLocalLlmPlatform
    with MockPlatformInterfaceMixin
    implements OnenmLocalLlmPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final OnenmLocalLlmPlatform initialPlatform = OnenmLocalLlmPlatform.instance;

  test('$MethodChannelOnenmLocalLlm is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOnenmLocalLlm>());
  });

  test('getPlatformVersion', () async {
    OnenmLocalLlm onenmLocalLlmPlugin = OnenmLocalLlm();
    MockOnenmLocalLlmPlatform fakePlatform = MockOnenmLocalLlmPlatform();
    OnenmLocalLlmPlatform.instance = fakePlatform;

    expect(await onenmLocalLlmPlugin.getPlatformVersion(), '42');
  });
}
