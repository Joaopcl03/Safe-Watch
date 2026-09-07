import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/routes/app_route.dart';
import 'package:safe_watch/core/theme/theme.dart';
import 'package:safe_watch/core/theme/custom_text_theme.dart';
import 'package:safe_watch/features/auth/controllers/auth_controller.dart';
import 'package:safe_watch/features/auth/models/auth_state.dart';
import 'package:safe_watch/shared/widgets/sw_input_text_form.dart';

// ============================================================================
// Safe Watch — Login Template
// ============================================================================
// Tela de autenticação (login/registro).
//
// Fluxo de dados:
//   LoginTemplate (esta tela)
//     → ref.read(authControllerProvider.notifier).signIn(...)
//       → AuthRepository.signInWithEmail(...)
//         → retorna AuthState
//     → ref.watch(authControllerProvider) → rebuida UI conforme estado
// ============================================================================

/// Tela de login do Safe Watch.
///
/// Usa [ConsumerStatefulWidget] para acessar providers Riverpod
/// e manter estado local do formulário (controllers de texto).
class LoginTemplate extends ConsumerStatefulWidget {
  const LoginTemplate({super.key});

  @override
  ConsumerState<LoginTemplate> createState() => _LoginTemplateState();
}

class _LoginTemplateState extends ConsumerState<LoginTemplate> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observa o estado de autenticação via Riverpod.
    // Quando o estado muda, o widget é reconstruído automaticamente.
    final authState = ref.watch(authControllerProvider);

    // Listener para navegação após login bem-sucedido.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go(SwRoutes.search);
      }
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: SwSupportColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SwSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / Título ────────────────────────────────
                  Icon(
                    Icons.movie_filter_outlined,
                    size: 80,
                    color: SwBrandColors.primary,
                  ),
                  const SizedBox(height: SwSpacing.md),
                  Text(
                    'Safe Watch',
                    textAlign: TextAlign.center,
                    style: getTextStyle(
                      context,
                      typo: SwTypeTypography.h1,
                      color: SwBrandColors.primary,
                    ),
                  ),
                  const SizedBox(height: SwSpacing.xs),
                  Text(
                    'Registre tudo que você assiste',
                    textAlign: TextAlign.center,
                    style: getTextStyle(
                      context,
                      typo: SwTypeTypography.body,
                      color: SwNeutralColors.gray600,
                    ),
                  ),
                  const SizedBox(height: SwSpacing.xxl),

                  // ── Campo de Email ───────────────────────────────
                  SwInputTextForm.primary(
                    controller: _emailController,
                    hintText: 'Email',
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: SwNeutralColors.gray500,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SwSpacing.md),

                  // ── Campo de Senha ───────────────────────────────
                  SwInputTextForm.password(
                    controller: _passwordController,
                    hintText: 'Senha',
                    labelText: 'Senha',
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe sua senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter ao menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: SwSpacing.lg),

                  // ── Botão de Login ───────────────────────────────
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SwNeutralColors.white,
                              ),
                            )
                          : Text(
                              'Entrar',
                              style: getTextStyle(
                                context,
                                typo: SwTypeTypography.button,
                                color: SwNeutralColors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: SwSpacing.md),

                  // ── Link para registro ───────────────────────────
                  TextButton(
                    onPressed: () {
                      // TODO: Navegar para tela de registro
                    },
                    child: Text(
                      'Não tem conta? Registre-se',
                      style: getTextStyle(
                        context,
                        typo: SwTypeTypography.body,
                        color: SwBrandColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // Chama o controller para realizar o login.
      // Fluxo: Template → Controller → Repository → Model
      ref.read(authControllerProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }
}
