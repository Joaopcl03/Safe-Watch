import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_watch/core/theme/theme.dart';

// ============================================================================
// Safe Watch — Bottom Navigation Shell
// ============================================================================
// Barra inferior no estilo TV Time: fundo preto, linha fina no topo,
// ícones outline com rótulo; item ativo em branco, inativos em cinza.
// Usado com StatefulShellRoute do go_router para manter o nav bar visível
// em todas as telas principais.
// ============================================================================

/// Shell com a barra de navegação inferior do Safe Watch.
///
/// Envolve as telas principais (Séries, Filmes, Explorar, Perfil)
/// mantendo o nav bar visível durante a navegação.
class SwBottomNavShell extends StatelessWidget {
  const SwBottomNavShell({
    required this.navigationShell,
    super.key,
  });

  /// O child widget fornecido pelo [StatefulShellRoute].
  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.tv_outlined, label: 'Séries'),
    _NavItem(icon: Icons.movie_creation_outlined, label: 'Filmes'),
    _NavItem(icon: Icons.search, label: 'Explorar'),
    _NavItem(icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: SwSurfaceColors.background,
          border: Border(
            top: BorderSide(color: SwSurfaceColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      selected: navigationShell.currentIndex == i,
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? SwNeutralColors.white : SwNeutralColors.gray600;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 30),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
