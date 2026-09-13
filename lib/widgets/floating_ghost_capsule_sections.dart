// ignore_for_file: invalid_use_of_protected_member

part of 'floating_ghost_capsule.dart';

extension _FloatingGhostCapsuleSections on _FloatingGhostCapsuleState {
  Widget _buildDialChassis(
    double currentY,
    double screenW,
    double topPadding,
    double availableH,
  ) {
    const totalBoxW =
        _FloatingGhostCapsuleState._orbitRadius +
        _FloatingGhostCapsuleState._satelliteSize +
        16;
    const totalBoxH =
        (_FloatingGhostCapsuleState._orbitRadius * 2) +
        _FloatingGhostCapsuleState._satelliteSize +
        16;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        // When collapsed, tightly bound to the hub to prevent dead zones
        width: _isExpanded
            ? totalBoxW
            : _FloatingGhostCapsuleState._quadrantRadius,
        height: _isExpanded
            ? totalBoxH
            : _FloatingGhostCapsuleState._quadrantHeight,
        child: Stack(
          alignment: _isRightSide
              ? Alignment.centerRight
              : Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // Morphing satellites & single continuous connecting arc
            if (_isExpanded)
              AnimatedBuilder(
                animation: _morphController,
                builder: (context, child) {
                  return _buildSatellitesAndMorphArc(totalBoxW, totalBoxH);
                },
              ),

            // The 25% edge quadrant (docked flush against the bezel)
            GestureDetector(
              key: const Key('radial_edge_quadrant'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpansion,
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _dimTimer?.cancel();
                widget.onOpenMenu();
              },
              onPanStart: (_) {
                _dimTimer?.cancel();
                if (_isExpanded) {
                  _collapse();
                }
                setState(() {
                  _isInteracting = true;
                  _opacity = 1.0;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  final newY =
                      (currentY + details.delta.dy - topPadding) / availableH;
                  _dy = newY.clamp(0.0, 1.0);
                  if (details.globalPosition.dx < screenW * 0.4) {
                    _isRightSide = false;
                  } else if (details.globalPosition.dx > screenW * 0.6) {
                    _isRightSide = true;
                  }
                });
              },
              onPanEnd: (_) {
                setState(() => _isInteracting = false);
                _resetDimTimer();
                _savePosition();
              },
              child: AnimatedBuilder(
                animation: _hubRecoilAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scaleX: _hubRecoilAnimation.value,
                    alignment: _isRightSide
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildQuadrantBezel(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Solid-color 25% radial bezel docked on screen edge
  /// Minimalist obsidian body + crisp solid cyan hairline border
  Widget _buildQuadrantBezel() {
    final outerRadius = _isRightSide
        ? const BorderRadius.only(
            topLeft: Radius.circular(
              _FloatingGhostCapsuleState._quadrantRadius,
            ),
            bottomLeft: Radius.circular(
              _FloatingGhostCapsuleState._quadrantRadius,
            ),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(
              _FloatingGhostCapsuleState._quadrantRadius,
            ),
            bottomRight: Radius.circular(
              _FloatingGhostCapsuleState._quadrantRadius,
            ),
          );

    return Container(
      width: _FloatingGhostCapsuleState._quadrantRadius,
      height: _FloatingGhostCapsuleState._quadrantHeight,
      decoration: BoxDecoration(
        color: _FloatingGhostCapsuleState._obsidianSolid,
        borderRadius: outerRadius,
        border: Border.all(
          color: _isReloading
              ? AppTheme.cyan
              : (_isExpanded
                    ? AppTheme.cyan
                    : AppTheme.cyan.withValues(alpha: 0.80)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 14,
            offset: Offset(_isRightSide ? -3 : 3, 3),
          ),
          BoxShadow(
            color: AppTheme.cyan.withValues(
              alpha: _isExpanded || _isReloading ? 0.35 : 0.16,
            ),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
            left: _isRightSide ? 8 : 0,
            right: !_isRightSide ? 8 : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.isCliConnected
                      ? AppTheme.cyan
                      : AppTheme.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (widget.isCliConnected)
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                PhosphorIconsRegular.lightning,
                size: 16,
                color: _isReloading
                    ? AppTheme.cyan
                    : (_isExpanded ? Colors.white : AppTheme.cyan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Satellites blooming along the radial trajectory with the single connected arc line
  Widget _buildSatellitesAndMorphArc(double totalW, double totalH) {
    final progress = _morphAnimation.value;
    final arcProgress = _arcProgressAnimation.value;
    final angleRad = _FloatingGhostCapsuleState._orbitAngleDeg * math.pi / 180;

    // Anchor center on the screen bezel edge
    final anchorX = _isRightSide ? totalW : 0.0;
    final anchorY = totalH / 2;

    // Radial distance expands from 0 to full orbit radius
    final currentR = _FloatingGhostCapsuleState._orbitRadius * progress;

    // Satellite centers along the arc trajectory
    final double reloadCenterX =
        anchorX + (_isRightSide ? -1 : 1) * currentR * math.cos(angleRad);
    final double reloadCenterY = anchorY - currentR * math.sin(angleRad);

    final double menuCenterX =
        anchorX + (_isRightSide ? -1 : 1) * currentR * math.cos(angleRad);
    final double menuCenterY = anchorY + currentR * math.sin(angleRad);

    final double halfSat = _FloatingGhostCapsuleState._satelliteSize / 2;

    // Subtle rotational inertia during transit
    final iconRotation = (1.0 - progress.clamp(0.0, 1.0)) * 0.22;

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Single continuous luminous cyan arc line (from top bezel to bottom bezel)
          CustomPaint(
            size: Size(totalW, totalH),
            painter: _MorphingOrbitArcPainter(
              isRightSide: _isRightSide,
              progress: arcProgress,
              orbitRadius: _FloatingGhostCapsuleState._orbitRadius,
              lineColor: AppTheme.cyan,
            ),
          ),

          // 1. Top Satellite: Hot Reload (⚡)
          Positioned(
            left: reloadCenterX - halfSat,
            top: reloadCenterY - halfSat,
            child: Transform.scale(
              scale: progress.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: -iconRotation,
                child: _buildSatelliteButton(
                  key: const Key('capsule_satellite_reload'),
                  icon: PhosphorIconsRegular.lightning,
                  iconColor: AppTheme.cyan,
                  tooltip: 'Hot Reload',
                  onTap: _triggerReloadFromSatellite,
                  isPulsing: _isReloading,
                ),
              ),
            ),
          ),

          // 2. Bottom Satellite: Dev Menu (🎛️)
          Positioned(
            left: menuCenterX - halfSat,
            top: menuCenterY - halfSat,
            child: Transform.scale(
              scale: progress.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: iconRotation,
                child: _buildSatelliteButton(
                  key: const Key('capsule_satellite_menu'),
                  icon: PhosphorIconsRegular.slidersHorizontal,
                  iconColor: AppTheme.cyan,
                  tooltip: 'Dev Menu',
                  onTap: _triggerMenuFromSatellite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Solid-color circular satellite puck with crisp 1.2px cyan rim
  Widget _buildSatelliteButton({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
    bool isPulsing = false,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: _FloatingGhostCapsuleState._satelliteSize,
          height: _FloatingGhostCapsuleState._satelliteSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _FloatingGhostCapsuleState._obsidianSolid,
            border: Border.all(
              color: isPulsing
                  ? AppTheme.cyan
                  : AppTheme.cyan.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.70),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: isPulsing ? 0.60 : 0.25),
                blurRadius: isPulsing ? 18 : 10,
                spreadRadius: isPulsing ? 2.0 : 0.5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 21,
              color: iconColor,
              shadows: [
                Shadow(
                  color: AppTheme.cyan.withValues(alpha: 0.75),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
