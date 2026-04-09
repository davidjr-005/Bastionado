# Guía de Bastionado — TP-Link Archer AX55 (AX3000, Wi-Fi 6)

## Resumen ejecutivo

El TP-Link Archer AX55 es un router Wi-Fi 6 (802.11ax) de gama media orientado a uso doméstico y SOHO (Small Office/Home Office), con capacidad AX3000, soporte para 2.4 GHz y 5 GHz simultáneos, cuatro puertos Gigabit Ethernet, puerto USB 3.0 para almacenamiento compartido, y servidor VPN integrado (OpenVPN y WireGuard). A pesar de ser un dispositivo orientado al consumidor, su historial de vulnerabilidades y su exposición como puerta de entrada a redes domésticas lo convierten en un objetivo de alto valor para atacantes.

Esta guía recoge las medidas de bastionado ordenadas por criticidad, justificadas técnicamente y vinculadas a CVEs reales publicados entre 2022 y 2026 en la familia Archer de TP-Link. El objetivo es reducir la superficie de ataque al mínimo operativo sin comprometer la funcionalidad legítima del dispositivo.

> **Referencia al emulador:** Todas las rutas de configuración indicadas en esta guía han sido verificadas sobre el emulador web oficial de TP-Link, accesible en https://www.tp-link.com/us/support/emulator/. El emulador permite explorar la interfaz de administración sin disponer del hardware físico.

***

## 1. Superficie de ataque y threat model

Antes de aplicar medidas, es necesario identificar los vectores de ataque relevantes para este dispositivo:

| Vector | Descripción | Probabilidad | Impacto |
|--------|-------------|-------------|---------|
| Acceso al panel web desde LAN | Cualquier dispositivo en la red local puede intentar autenticarse en el panel admin | Alta | Crítico |
| Acceso al panel web desde WAN | Si la administración remota está habilitada, el panel queda expuesto a Internet | Media | Crítico |
| Explotación de servicios activos (UPnP, FTP, Telnet) | Servicios innecesarios activos amplían la superficie de ataque | Alta | Alto |
| Captura de credenciales Wi-Fi | Ataques de diccionario offline contra handshakes WPA2 | Alta | Alto |
| Ataques a dispositivos IoT en la misma red | Movimiento lateral desde un dispositivo IoT comprometido hacia equipos críticos | Media | Alto |
| Explotación de vulnerabilidades conocidas (CVEs) | Firmware sin parchear vulnerable a RCE, command injection o auth bypass | Alta | Crítico |
| Ataque físico (reset de fábrica) | Acceso físico al botón de reset restaura configuración por defecto | Baja | Alto |

***

## 2. CVEs relevantes en la familia Archer (2022–2026)

La familia Archer de TP-Link ha acumulado un historial significativo de vulnerabilidades. Aunque algunos CVEs afectan formalmente a otros modelos de la misma familia, todos comparten base de código y módulos de servicio similares al AX55, lo que hace estas vulnerabilidades relevantes por proximidad arquitectónica.

| CVE | CVSS | Afecta a | Descripción | Medida de mitigación |
|-----|------|---------|-------------|----------------------|
| CVE-2025-15517 | Crítica | Archer NX200/NX210/NX500/NX600 | Authorization Bypass: falta de comprobación de autenticación en endpoints HTTP CGI, permite operaciones privilegiadas (subida de firmware, cambios de configuración) sin credenciales | Desactivar admin remota WAN + actualizar firmware |
| CVE-2025-15518 | Alta | Archer NX series | Hardcoded cryptographic key en archivos de configuración, permite descifrar y manipular la configuración del dispositivo | Actualizar firmware |
| CVE-2025-15519 | Alta | Archer NX series | Input validation flaw en CGI endpoints, permite ejecución de comandos arbitrarios | Actualizar firmware + deshabilitar servicios expuestos |
| CVE-2025-14756 | Alta | Archer MR600 v5 | Command Injection autenticado en la interfaz de administración vía browser console, permite ejecución de comandos del sistema con privilegios de root | Cambiar contraseña admin, actualizar firmware |
| CVE-2025-7850 | Alta | Archer con WireGuard | OS Command Injection vía configuración WireGuard VPN en el panel web | No usar WireGuard en firmware sin parchear |
| CVE-2025-7851 | Alta | Archer (múltiples) | Código de debug residual permite acceso root no autorizado | Actualizar firmware |
| CVE-2025-62501 | 7.0 | Archer (múltiples) | SSH Hostkey misconfiguration en módulo `tmpserver`, permite ataque MITM para captura de credenciales | Deshabilitar SSH si no se usa, actualizar firmware |
| CVE-2026-0630 / CVE-2026-22221-22229 | Hasta 8.6 | Archer BE230 Wi-Fi 7 | Múltiples OS Command Injection en módulos web, VPN, cloud y backup de configuración, permite control total del dispositivo con credenciales admin | Principio de mínimo privilegio en acceso admin |
| CVE-2022-30075 | Alta | Archer AX50 | RCE autenticado en firmware 210730, permite toma de control completa | Actualizar a firmware ≥ 220303 |

> **Fuentes:** TP-Link Security Advisory Portal, NVD/NIST, CSA Singapore Advisory AL-2026-028, INCIBE.

***

## 3. Medidas de bastionado

Las medidas están organizadas de mayor a menor criticidad. Para cada una se indica la ruta exacta en el panel web del AX55, la justificación técnica y el riesgo asociado si se omite.

***

### 3.1 Actualizar el firmware inmediatamente

**Criticidad:** 🔴 CRÍTICA  
**Ruta:** `Advanced → System → Firmware Upgrade`

La mayoría de CVEs listados en la sección anterior tienen parches publicados. Un dispositivo con firmware desactualizado es potencialmente explotable de forma remota. La CSA de Singapur emitió en marzo de 2026 un aviso urgente instando a usuarios de dispositivos Archer a actualizar de inmediato tras la publicación de CVE-2025-15517.

**Pasos:**
1. Navegar a `Advanced → System → Firmware Upgrade`
2. Seleccionar **Check for Updates** para buscar automáticamente
3. Alternativamente, descargar el firmware manualmente desde `https://www.tp-link.com/es/support/download/archer-ax55/` y cargarlo manualmente
4. Verificar siempre el **hash SHA256** del archivo descargado antes de instalarlo
5. Activar **Auto Firmware Upgrade** (si está disponible en el firmware actual) para recibir parches automáticamente

> **Advertencia:** Investigadores han documentado que TP-Link ha publicado parches incompletos en el pasado (como el de CVE-2024-21827) que dejaban funcionalidad de debug activa, generando nuevos vectores de ataque (CVE-2025-7851). Revisar siempre el changelog completo del firmware antes de actualizar.

***

### 3.2 Cambiar credenciales de administración por defecto

**Criticidad:** 🔴 CRÍTICA  
**Ruta:** `Advanced → System → Administration → Account Management`

Las credenciales `admin/admin` o derivadas del número de serie del dispositivo son las primeras que prueban las botnets (Mirai y variantes). CVE-2025-14756 requiere autenticación previa, lo que significa que credenciales robustas son una barrera efectiva incluso frente a exploits que requieren acceso autenticado.

**Requisitos de la contraseña:**
- Longitud mínima: **16 caracteres**
- Combinación de: mayúsculas, minúsculas, números y símbolos
- No reutilizar contraseñas de otros servicios
- Almacenar en un gestor de contraseñas (Bitwarden, KeePassXC)

**Adicionalmente:**
- Cambiar el nombre de usuario (no usar el nombre de usuario `admin` por defecto)
- Configurar un **timeout de sesión** corto (5-10 minutos) para cerrar sesiones administrativas inactivas

***

### 3.3 Deshabilitar la administración remota desde WAN

**Criticidad:** 🔴 CRÍTICA  
**Ruta:** `Advanced → System → Administration → Remote Management`

CVE-2025-15517 demostró que la ausencia de comprobaciones de autenticación en ciertos endpoints CGI del servidor HTTP del router permite operaciones privilegiadas sin credenciales. Si la administración remota está activa, este tipo de vulnerabilidades son explotables directamente desde Internet.

**Pasos:**
1. Verificar que **Remote Management** está desactivado (debería estarlo por defecto)
2. Confirmar que no hay ningún port-forwarding manual al puerto 80, 443 o al puerto de administración
3. Verificar desde el exterior con: `curl -k https://[IP-WAN]:443` — debe dar timeout o connection refused

> **Regla de oro:** Si se necesita acceso remoto al router, usar VPN antes de acceder al panel (ver sección 3.11). Nunca exponer el panel directamente a Internet.

***

### 3.4 Forzar HTTPS y cambiar el puerto de administración

**Criticidad:** 🟠 ALTA  
**Ruta:** `Advanced → System → Administration`

Con HTTP en texto plano, las credenciales se transmiten sin cifrar. CVE-2025-62501 sobre SSH Hostkey misconfiguration ejemplifica cómo la ausencia de cifrado en protocolos de gestión puede derivar en capturas de credenciales por MITM.

**Pasos:**
1. Activar **HTTPS** para el acceso al panel web
2. Cambiar el puerto de administración de `443` a un puerto no estándar (ej. `58443`)
3. Aceptar el certificado autofirmado en el navegador y fijarlo como excepción permanente

***

### 3.5 Deshabilitar UPnP

**Criticidad:** 🟠 ALTA  
**Ruta:** `Advanced → NAT Forwarding → UPnP`

UPnP (Universal Plug and Play) permite a cualquier dispositivo de la red interna abrir puertos en el firewall del router **sin autenticación**. Este mecanismo ha sido abusado por malware para crear canales de comunicación encubiertos y exponer servicios internos a Internet. No existe ningún caso de uso doméstico que justifique mantener UPnP activo si se gestionan manualmente los port-forwardings necesarios.

**Pasos:**
1. Navegar a `Advanced → NAT Forwarding → UPnP`
2. Deshabilitar completamente
3. Configurar manualmente los reenvíos de puertos necesarios (consolas de videojuegos, servidores locales, etc.) en `Advanced → NAT Forwarding → Port Forwarding`

***

### 3.6 Configurar WPA3 y deshabilitar WPS

**Criticidad:** 🟠 ALTA  
**Ruta:** `Wireless → Wireless Settings → Security`

WEP es completamente inseguro (roto en minutos). WPA con TKIP es vulnerable a ataques prácticos. WPA2-Personal con contraseñas débiles es susceptible a ataques de diccionario offline contra el handshake capturado con herramientas como `aircrack-ng` o `hashcat`. WPS con autenticación por PIN es vulnerable a fuerza bruta (el PIN de 8 dígitos se verifica en dos bloques de 4, reduciendo el espacio de búsqueda a ~11.000 combinaciones).

**Pasos:**
1. Navegar a `Wireless → Wireless Settings → Security` para cada banda (2.4 GHz y 5 GHz)
2. Seleccionar **WPA3-Personal** o **WPA2/WPA3-Personal** (modo mixto para compatibilidad con dispositivos que no soportan WPA3)
3. Establecer contraseña Wi-Fi de **mínimo 20 caracteres** aleatorios
4. Deshabilitar WPS: `Advanced → Wireless → WPS → deshabilitar`

> **Nota sobre WPA3:** WPA3 usa el protocolo SAE (Simultaneous Authentication of Equals) en lugar del handshake de 4 vías de WPA2, lo que elimina los ataques de diccionario offline.

***

### 3.7 Segmentar la red: red de invitados e IoT

**Criticidad:** 🟠 ALTA  
**Ruta:** `Advanced → Wireless → Guest Network`

Los dispositivos IoT (cámaras IP, smart TVs, asistentes de voz, domótica) son vectores de ataque frecuentes con escasas garantías de seguridad. Si están en la misma red que los equipos principales (ordenadores, NAS, servidores locales), un compromiso de cualquier dispositivo IoT puede derivar en movimiento lateral hacia toda la red.

**Pasos:**
1. Crear una red Wi-Fi separada para dispositivos IoT y visitantes: `Advanced → Wireless → Guest Network`
2. Activar **Access Control** para que la red de invitados/IoT no pueda alcanzar la LAN principal (opción "Access to local network: Disabled")
3. Activar **Client Isolation** (si está disponible) para que los dispositivos IoT tampoco puedan comunicarse entre sí
4. Considerar asignar a los dispositivos IoT una IP en un rango diferente para facilitar la identificación en logs

**Esquema de red recomendado:**

```
Internet
    │
[Archer AX55]
    │
    ├── LAN Principal (192.168.1.0/24)
    │       ├── PC, portátiles, NAS, servidores
    │       └── Acceso total entre dispositivos
    │
    └── Red IoT/Invitados (192.168.2.0/24) [Guest Network]
            ├── Smart TV, cámaras, Alexa, domótica
            ├── Client Isolation activo
            └── Sin acceso a LAN Principal
```

***

### 3.8 Deshabilitar servicios innecesarios

**Criticidad:** 🟠 ALTA

Cada servicio activo es una potencial superficie de ataque. El principio de mínimo privilegio aplicado a servicios de red dicta que cualquier servicio no estrictamente necesario debe estar desactivado.

| Servicio | Ruta en el panel | Riesgo | Acción |
|----------|-----------------|--------|--------|
| Telnet | `Advanced → System` | Protocolo en texto plano, credenciales expuestas | **Deshabilitar** |
| FTP del NAS (USB) | `Advanced → USB Settings → File Sharing` | Exposición de archivos, autenticación débil por defecto | Deshabilitar si no se usa |
| UPnP | `Advanced → NAT Forwarding → UPnP` | Apertura de puertos sin autenticación | **Deshabilitar** |
| IPTV/IGMP Proxy | `Advanced → Network → IPTV` | Amplifica tráfico multicast innecesariamente | Deshabilitar si no se usa IPTV |
| Ping desde WAN | `Advanced → Security → Firewall` | Permite reconocimiento de la IP pública del router | **Deshabilitar** |
| IPv6 | `Advanced → IPv6` | Si no se usa, reduce la superficie de ataque | Deshabilitar si no es necesario |
| SSH (si existe) | `Advanced → System` | CVE-2025-62501 afecta a la implementación SSH | Deshabilitar si no se usa |

***

### 3.9 Configurar el Firewall SPI y protección DoS

**Criticidad:** 🟠 ALTA  
**Ruta:** `Advanced → Security → Firewall`

El firewall SPI (Stateful Packet Inspection) analiza el estado de cada conexión, descartando paquetes que no correspondan a una conexión iniciada desde la red interna. Sin él, el router aceptaría tráfico entrante no solicitado.

**Pasos:**
1. Verificar que **SPI Firewall** está activo (activo por defecto — confirmar que no se ha desactivado)
2. Activar protecciones específicas:
   - **DoS Protection:** activo
   - **ICMP-Flood Attack Filtering:** activo (threshold: 50 paquetes/seg)
   - **UDP-Flood Attack Filtering:** activo (threshold: 500 paquetes/seg)
   - **TCP-SYN-Flood Attack Filtering:** activo (threshold: 50 paquetes/seg)
3. Activar **ALG (Application Layer Gateway)** solo para los protocolos estrictamente necesarios

***

### 3.10 Cambiar el SSID por defecto y gestionar la visibilidad

**Criticidad:** 🟡 MEDIA  
**Ruta:** `Wireless → Wireless Settings → Wireless Name (SSID)`

Un SSID que revela el modelo del router (ej. `TP-Link_AX55_XXXX`) permite a un atacante identificar inmediatamente el dispositivo y buscar exploits específicos sin necesidad de reconocimiento adicional.

**Pasos:**
1. Cambiar el SSID a un nombre que no revele fabricante, modelo ni datos personales (nombre, dirección, etc.)
2. Aplicar a ambas bandas (2.4 GHz y 5 GHz) y a la red de invitados/IoT

> **Sobre ocultar el SSID:** No constituye una medida de seguridad robusta. Una red con SSID oculto es trivialmente detectable con herramientas de análisis Wi-Fi como `airodump-ng` o `Wireshark`. Además, los dispositivos que se conectan a redes ocultas emiten probe requests con el SSID en texto plano, lo que puede facilitar ataques de gemelo malicioso (evil twin).

***

### 3.11 Configurar acceso remoto seguro mediante VPN

**Criticidad:** 🟡 MEDIA  
**Ruta:** `Advanced → VPN Server → OpenVPN`

Si se necesita acceso al router o a la red doméstica desde el exterior, la alternativa segura es establecer un túnel VPN en lugar de exponer servicios directamente.

**Opciones disponibles en el AX55:**
- **OpenVPN Server** (recomendado): protocolo maduro, bien auditado, amplia compatibilidad
- **WireGuard Server:** más moderno y eficiente, pero **se recomienda extrema precaución** dado CVE-2025-7850 (OS Command Injection vía configuración WireGuard) — actualizar firmware antes de habilitarlo

**Configuración recomendada para OpenVPN:**
- Protocolo: **UDP** (más eficiente)
- Puerto: no estándar (cambiar del puerto 1194 predeterminado)
- Cifrado: **AES-256-GCM**
- Autenticación: certificado + contraseña (autenticación de dos factores)
- Exportar y almacenar el certificado CA en un lugar seguro; **nunca compartirlo**

***

### 3.12 Configurar servidores DNS seguros

**Criticidad:** 🟡 MEDIA  
**Ruta:** `Advanced → Network → Internet → DNS`

Los servidores DNS del ISP pueden no soportar DNSSEC, pueden registrar todas las consultas del hogar y son susceptibles a ataques de envenenamiento de caché (DNS Spoofing/Cache Poisoning).

**Alternativas recomendadas:**

| Proveedor | Primario | Secundario | Características destacadas |
|-----------|----------|------------|---------------------------|
| Quad9 | `9.9.9.9` | `149.112.112.112` | Bloqueo de dominios maliciosos, DNSSEC, privacidad |
| Cloudflare | `1.1.1.1` | `1.0.0.1` | Alta velocidad, privacy-first, soporta DoH/DoT |
| NextDNS | Personalizado | Personalizado | Filtrado avanzado por categorías, logs controlables |

**Adicionalmente:**
- Activar **DNS Rebinding Protection** si está disponible: previene que dominios externos resuelvan a IPs privadas, un vector de ataque para comprometer routers y dispositivos internos

***

### 3.13 Activar y monitorizar los logs del sistema

**Criticidad:** 🟡 MEDIA  
**Ruta:** `Advanced → System → System Log`

Los logs permiten detectar actividad anómala: intentos de acceso repetidos, cambios de configuración no autorizados, conexiones en puertos inusuales o reinicios inesperados del dispositivo.

**Pasos:**
1. Activar el registro del sistema con nivel de detalle máximo
2. Configurar **Syslog remoto** si se dispone de un servidor de logs:
   - Servidor ELK Stack (Elasticsearch + Logstash + Kibana)
   - Graylog
   - Solución sencilla: `rsyslog` en un Raspberry Pi
3. Configurar alertas automáticas (si el firmware lo permite) para: login desde nueva IP, cambio de contraseña, actualización de firmware

**Indicadores de compromiso (IoC) a buscar en los logs:**
- Múltiples intentos de login fallidos en corto espacio de tiempo → posible fuerza bruta
- Cambios de configuración en horarios no habituales → posible acceso no autorizado
- Reinicio inesperado del dispositivo → posible explotación activa de una vulnerabilidad
- Nuevas reglas de port-forwarding creadas automáticamente → posible UPnP abusado por malware

***

### 3.14 Hardening del acceso USB

**Criticidad:** 🟡 MEDIA  
**Ruta:** `Advanced → USB Settings`

El puerto USB 3.0 del AX55 permite compartir almacenamiento en red (FTP, Samba) y conectar impresoras. Si no está configurado correctamente, puede exponer archivos a toda la red o, en escenarios avanzados, actuar como vector de ataque.

**Pasos:**
1. Deshabilitar el **compartición de archivos USB** si no se usa: `Advanced → USB Settings → File Sharing → deshabilitar`
2. Si se usa, activar **Secure Sharing** (autenticación usuario/contraseña) y limitar el acceso solo a cuentas específicas
3. **No conectar memorias USB desconocidas:** el AX55 monta automáticamente cualquier dispositivo USB conectado

***

### 3.15 Hardening físico del dispositivo

**Criticidad:** 🟡 MEDIA

| Medida | Justificación |
|--------|---------------|
| Ubicar el router en zona de acceso restringido | El botón de reset restaura la configuración de fábrica sin autenticación, anulando todas las medidas aplicadas |
| Deshabilitar el botón WPS físico | `Advanced → Wireless → WPS → desactivar`. Aunque WPS ya esté deshabilitado por software, el botón físico puede reactivarlo |
| Deshabilitar el botón de LED si no es necesario | No aporta seguridad directa, pero reduce la información visual accesible a terceros sobre el estado del dispositivo |
| Revisar quién tiene acceso físico al router en entornos compartidos | En pisos compartidos u oficinas, el acceso físico es un vector de ataque real |

***

## 4. Mantenimiento y revisión periódica

El bastionado de un router no es una tarea puntual, sino un proceso continuo. Las siguientes acciones deben realizarse de forma regular:

| Tarea | Frecuencia | Herramienta |
|-------|-----------|-------------|
| Verificar disponibilidad de nuevo firmware | Mensual | Portal oficial TP-Link / Auto-update |
| Revisar avisos de seguridad de TP-Link | Mensual | https://www.tp-link.com/us/press/security-advisory/ |
| Revisar logs del sistema | Semanal | Panel web → System Log |
| Auditar dispositivos conectados a la red | Mensual | `Advanced → Network Map` |
| Verificar que no hay port-forwardings no reconocidos | Mensual | `Advanced → NAT Forwarding` |
| Revisar la configuración completa del router | Cada 90 días | Panel web completo |
| Cambiar contraseñas Wi-Fi | Cada 6-12 meses | `Wireless → Wireless Settings` |

***

## 5. Checklist de bastionado rápido

Lista de verificación para auditar el estado de seguridad del dispositivo. Una instalación segura debe tener todos los ítems marcados:

### Crítico (prioridad máxima)
- [ ] Firmware actualizado a la última versión disponible
- [ ] Credenciales de administración cambiadas (usuario y contraseña no por defecto)
- [ ] Administración remota desde WAN desactivada
- [ ] UPnP desactivado
- [ ] WPA3 o WPA2/WPA3 configurado en todas las redes Wi-Fi
- [ ] WPS desactivado (software y botón físico)

### Alto (implementar cuanto antes)
- [ ] Acceso al panel solo por HTTPS en puerto no estándar
- [ ] SPI Firewall activo con protección DoS/SYN/ICMP/UDP Flood
- [ ] Red separada para dispositivos IoT/invitados con Client Isolation activo
- [ ] Servicios no utilizados desactivados (Telnet, FTP USB, IPv6, SSH, IGMP)
- [ ] Ping desde WAN desactivado

### Medio (implementar en segunda fase)
- [ ] SSID cambiado (sin revelar modelo, marca ni datos personales)
- [ ] DNS personalizado configurado (Quad9 o Cloudflare)
- [ ] Logs del sistema activados
- [ ] Syslog remoto configurado (si se dispone de servidor)
- [ ] Compartición USB desactivada o con autenticación activada
- [ ] Contraseña Wi-Fi de mínimo 20 caracteres

### Mantenimiento continuo
- [ ] Revisión mensual de nuevos avisos de seguridad de TP-Link
- [ ] Verificación mensual de firmware
- [ ] Revisión semanal de logs del sistema
- [ ] Auditoría trimestral de la configuración completa

***

## 6. Consideración avanzada: migración a firmware alternativo (OpenWrt)

Para usuarios con conocimientos técnicos avanzados, la sustitución del firmware propietario de TP-Link por **OpenWrt** es la medida de mayor impacto en la reducción de la superficie de ataque:

**Ventajas:**
- Elimina el código propietario potencialmente vulnerable, incluyendo código de debug residual como el explotado en CVE-2025-7851
- Control total sobre qué servicios están activos
- Actualizaciones de seguridad más frecuentes e independientes del fabricante
- Soporte para firewall avanzado (nftables), IDS/IPS embebido, y monitorización detallada

**Riesgos y consideraciones:**
- Anula la garantía del dispositivo
- Un proceso de flasheo incorrecto puede hacer el router irrecuperable ("brick")
- Verificar compatibilidad en https://openwrt.org/toh/ antes de proceder
- Requiere configuración desde cero (no migra configuración del firmware original)

***

## 7. Referencias y fuentes

- TP-Link Security Advisory Portal: https://www.tp-link.com/us/press/security-advisory/
- CVE-2025-15517 / Auth Bypass en Archer NX: https://www.tp-link.com/us/support/faq/5027/
- CSA Singapore Advisory AL-2026-028: https://www.csa.gov.sg/alerts-and-advisories/alerts/al-2026-028/
- CVE-2025-62501 (SSH Hostkey): https://nvd.nist.gov/vuln/detail/CVE-2025-62501
- CVE-2025-14756 (Command Injection MR600): https://www.cryptika.com/tp-link-archer-vulnerability-let-attackers-take-control-over-the-router/
- CVE-2026-0630 y múltiples (Archer BE230): https://lnkd.in/dWpuB4Nb
- Forescout — TP-Link Router Vulnerabilities (2025): https://www.forescout.com/blog/new-tp-link-router-vulnerabilities-a-primer-on-rooting-routers/
- LinuxSecurity — Securing TP-Link with OpenWRT: https://linuxsecurity.com/news/network-security/securing-your-tp-link-router-with-openwrt
- INCIBE — Múltiples vulnerabilidades TP-Link: https://www.incibe.es/empresas/avisos/multiples-vulnerabilidades-en-productos-de-tp-link-0
- TP-Link Emulador Web oficial (AX55 y otros modelos): https://www.tp-link.com/us/support/emulator/
- routersecurity.org — Router Security Checklist: https://routersecurity.org/checklist.php
- Manual oficial Archer AX55 REV4.0.0: https://www.scribd.com/document/862773416/Archer-AX55-UG-REV4-0-0-Router