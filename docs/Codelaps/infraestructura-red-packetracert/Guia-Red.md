summary: Infraestructura de red en dos sedes
id: infraestructura-red-packetracert
categories: ciberseguridad, linux, hardening
tags: ubuntu, luks, lvm, grub, seguridad, cifrado
status: Published
authors: David JR
Feedback Link: djimrui878@g.educaand.es

# Guía Completa: Infraestructura de Red Multi-Sede

## Tabla de Contenidos
1. [Topología y Arquitectura](#topología-y-arquitectura)
2. [Configuración de VLANs en Switches](#configuración-de-vlans-en-switches)
3. [Configuración de VLANs en Routers](#configuración-de-vlans-en-routers)
4. [Configuración de Routers](#configuración-de-routers)
5. [Enrutamiento Estático](#enrutamiento-estático)

---

## Topología y Arquitectura

### Estructura General
```
SEDE 1 (172.20.0.0/16)
├─ Router0-S1 (R0-S1) - gateway de VLANs
├─ Router1-S1 (R1-S1) - conecta a Router INTERMEDIO
├─ Switch0-S1 - conecta PCs a las VLANs
└─ PCs (PC0-PC8) en diferentes VLANs

ROUTER INTERMEDIO
├─ Conecta Sede 1 con Sede 2
└─ Realiza forwarding entre sedes

SEDE 2 (172.20.2.0/16)
├─ Router2-S2 (R2-S2) - conecta con Router INTERMEDIO
├─ Router3-S2 (R3-S2) - gateway de VLANs
├─ Switch0-S2 - conecta PCs a las VLANs
└─ PCs (PC9-PC17) en diferentes VLANs
```

### Conexiones Físicas
- **R0-S1 ↔ R1-S1**: FastEthernet0/0 a FastEthernet1/0 (192.168.1.0/30)
- **R1-S1 ↔ Router INTERMEDIO**: FastEthernet0/0 a FastEthernet0/0 (172.20.0.0/30)
- **Router INTERMEDIO ↔ R2-S2**: FastEthernet1/0 a FastEthernet0/0 (172.20.0.4/30)
- **R2-S2 ↔ R3-S2**: FastEthernet1/0 a FastEthernet0/0 (192.168.1.0/30)
- **Switch0-S1 ↔ Router0-S1**: interfaces de acceso a VLANs
- **Switch0-S2 ↔ Router3-S2**: interfaces de acceso a VLANs

---

## Configuración de VLANs en Switches

### En Switch0-S1 (Sede 1)

#### Crear VLANs
```
enable
config t
hostname Switch0-S1

! Crear VLAN 10 - TIC
vlan 10
 name TIC

! Crear VLAN 20 - Facturación
vlan 20
 name Facturación

! Crear VLAN 30 - Compras
vlan 30
 name Compras

! Crear VLAN 40 - RRHH
vlan 40
 name RRHH

! Crear VLAN 50 - Delivery
vlan 50
 name Delivery

! Crear VLAN 60 - Comunicacion_RRSS
vlan 60
 name Comunicacion_RRSS

! Crear VLAN 70 - Mantenimiento
vlan 70
 name Mantenimiento

! Crear VLAN 80 - Legal
vlan 80
 name Legal

! Crear VLAN 90 - Consejo_Administracion
vlan 90
 name Consejo_Administracion

exit

interface FastEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 1
 switchport trunk allowed vlan all

! Trunk hacia Switch1-S1
interface FastEthernet1/1
 switchport mode trunk
 switchport trunk allowed vlan all

! Trunk hacia Switch4-S1
interface FastEthernet1/4
 switchport mode trunk
 switchport trunk allowed vlan all

! Trunk hacia Switch2-S1
interface FastEthernet1/2
 switchport mode trunk
 switchport trunk allowed vlan all

! Trunk hacia Switch3-S1
interface FastEthernet1/3
 switchport mode trunk
 switchport trunk allowed vlan all

end
write memory
```

#### Verificar configuración VLAN
```
show vlan brief
show interfaces switchport
```

## En Switch1-S1
```
enable
config t
hostname Switch1-S1

vlan 10
 name TIC
vlan 20
 name Facturacion

exit

interface FastEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan all

interface FastEthernet1/1
 switchport mode access
 switchport access vlan 10

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet1/2
 switchport mode access
 switchport access vlan 20

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

end
write memory
```

### En Switch2-S1
```
enable
config t
hostname Switch2-S1

vlan 30
 name Compras
vlan 40
 name RRHH

exit

! TRUNK hacia Switch0-S1
interface FastEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan all

! ACCESS hacia PCs
interface FastEthernet1/1
 switchport mode access
 switchport access vlan 30

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet1/2
 switchport mode access
 switchport access vlan 40

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

end
write memory
```

## En Switch3-S1
```
enable
config t
hostname Switch3-S1

vlan 50
 name  Delivery
vlan 60
 name Comunicacion_RRSS

exit

! TRUNK hacia Switch0-S1
interface FastEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan all

! ACCESS hacia PCs
interface FastEthernet1/1
 switchport mode access
 switchport access vlan 50

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet1/2
 switchport mode access
 switchport access vlan 60

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

end
write memory
```

## En Switch4-S1
```
enable
config t
hostname Switch4-S1


vlan 70
 name Mantenimiento
vlan 80
 name Legal
vlan 90
 name Consejo_Administracion

exit

! TRUNK hacia Switch0-S1
interface FastEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan all

! ACCESS hacia PCs
interface FastEthernet1/1
 switchport mode access
 switchport access vlan 70

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet2/1
 switchport mode access
 switchport access vlan 80

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet3/1
 switchport mode access
 switchport access vlan 90

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

end
write memory
```

### En Switch0-S2 (Sede 2)

#### Crear VLANs
```
enable
config t
hostname Switch0-S2

! Crear VLAN 100
vlan 100
 name Operaciones

! Crear VLAN 110
vlan 110
 name RRHH

! Crear VLAN 120
vlan 120
 name Fianzas

! Crear VLAN 130
vlan 130
 name Seguridad

exit

! Trunk hacia Router3-S2 (gateway)
interface FastEthernet0/1
 switchport mode trunk
 switchport trunk native vlan 1
 switchport trunk allowed vlan all

! Trunk hacia Switch6-S2
interface FastEthernet1/1
 switchport mode trunk
 switchport trunk allowed vlan all

! Trunk hacia Switch7-S2
interface FastEthernet2/1
 switchport mode trunk
 switchport trunk allowed vlan all

end
write memory
```

## En Swicth6-S2
```
enable
config t
hostname Switch6-S2

! Crear TODAS las VLANs
vlan 100
 name Operaciones
vlan 110
 name RRHH
exit

! TRUNK hacia SwitchNT (core)
interface FastEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan all

! ACCESS hacia PCs
interface FastEthernet1/1
 switchport mode access
 switchport access vlan 100

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet2/1
 switchport mode access
 switchport access vlan 110

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

end
write memory
```
## En Switch7-S2
```
enable
config t
hostname Switch7-S2

vlan 120
 name Fianzas
vlan 130
 name Fianzas
exit

! TRUNK hacia SwitchNT (core)
interface FastEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan all

! ACCESS hacia PCs
interface FastEthernet1/1
 switchport mode access
 switchport access vlan 120

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

interface FastEthernet2/1
 switchport mode access
 switchport access vlan 130

 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

end
write memory
```

#### Verificar configuración VLAN
```
show vlan brief
show interfaces switchport
```

---

## Configuración de VLANs en Routers

### En Router0-S1 (R0-S1) - Sede 1

#### Crear subinterfaces VLAN
```
enable
config t
hostname Router0-S1

! VLAN 10 - TIC
interface FastEthernet1/0.10
 encapsulation dot1Q 10
 ip address 172.20.0.33 255.255.224.0

! VLAN 20 - Facturación
interface FastEthernet1/0.20
 encapsulation dot1Q 20
 ip address 172.20.0.65 255.255.224.0

! VLAN 30 - Compras
interface FastEthernet1/0.30
 encapsulation dot1Q 30
 ip address 172.20.0.97 255.255.255.224

! VLAN 40 - RRHH
interface FastEthernet1/0.40
 encapsulation dot1Q 40
 ip address 172.20.0.129 255.255.255.224

! VLAN 50 - Delivery
interface FastEthernet1/0.50
 encapsulation dot1Q 50
 ip address 172.20.0.161 255.255.255.224

! VLAN 60 - Comunicacion__RRSS
interface FastEthernet1/0.60
 encapsulation dot1Q 60
 ip address 172.20.0.193 255.255.255.224

! VLAN 70 - Mantenimiento
interface FastEthernet1/0.70
 encapsulation dot1Q 70
 ip address 172.20.0.225 255.255.255.240

! VLAN 80 - Departamento Legal
interface FastEthernet1/0.80
 encapsulation dot1Q 80
 ip address 172.20.0.241 255.255.255.240

! VLAN 90 - Consejo_Administración
interface FastEthernet1/0.90
 encapsulation dot1Q 90
 ip address 172.20.1.1 255.255.255.240

! Interfaz Trunk
interface FastEthernet1/1
 no ip address
 no shutdown

! Interfaz hacia firewall perimetral
interface FastEthernet0/1
 ip address 192.168.1.2 255.255.255.252
 no shutdown

end
write memory
```

### En Router3-S2 (R3-S2) - Sede 2

#### Crear subinterfaces VLAN
```
enable
config t
hostname Router3-S2

! VLAN 100 operaciones
interface FastEthernet1/0.100
 encapsulation dot1Q 100
 ip address 172.20.2.1 255.255.255.224

! VLAN 110 RRHH
interface FastEthernet1/0.110
 encapsulation dot1Q 110
 ip address 172.20.2.33 255.255.255.240

! VLAN 120 Fianzas
interface FastEthernet1/0.120
 encapsulation dot1Q 120
 ip address 172.20.2.49 255.255.255.240

! VLAN 130 Seguridad
interface FastEthernet1/0.130
 encapsulation dot1Q 130
 ip address 172.20.2.65 255.255.255.240

! Interfaz hacia firewall perimetral
interface FastEthernet0/1
 ip address 192.168.1.2 255.255.255.252
 no shutdown

! Interfaz Trunk
interface FastEthernet1/1
 no ip address
 no shutdown

end
write memory
```

---

## Configuración de Routers

### En Router1-S1 (R1-S1) - Sede 1

#### Interfaces de conexión
```
enable
config t
hostname Router1-S1

! Interfaz hacia Router0-S1
interface FastEthernet1/0
 ip address 192.168.1.1 255.255.255.252
 no shutdown

! Interfaz hacia Router INTERMEDIO
interface FastEthernet0/0
 ip address 172.20.0.1 255.255.255.252
 no shutdown

end
write memory
```

### En Router INTERMEDIO

#### Interfaces de conexión
```
enable
config t
hostname RouterIntermedio

! Interfaz hacia Router1-S1
interface FastEthernet0/0
 ip address 172.20.0.2 255.255.255.252
 no shutdown

! Interfaz hacia Router2-S2
interface FastEthernet1/0
 ip address 172.20.0.5 255.255.255.252
 no shutdown

end
write memory
```

### En Router2-S2 (R2-S2) - Sede 2

#### Interfaces de conexión
```
enable
config t
hostname Router2-S2

! Interfaz hacia Router INTERMEDIO
interface FastEthernet0/0
 ip address 172.20.0.6 255.255.255.252
 no shutdown

! Interfaz hacia Router3-S2
interface FastEthernet1/0
 ip address 192.168.1.1 255.255.255.252
 no shutdown

end
write memory
```

---

## Enrutamiento Estático

### En Router0-S1 (R0-S1)

Agregar rutas hacia Sede 2:
```
enable
config t

ip route 172.20.2.0 255.255.255.224 192.168.1.1
ip route 172.20.2.32 255.255.255.240 192.168.1.1
ip route 172.20.2.48 255.255.255.240 192.168.1.1
ip route 172.20.2.64 255.255.255.240 192.168.1.1

end
write memory
```

### En Router1-S1 (R1-S1)

Agregar rutas hacia Sede 2:
```cisco
enable
config t

ip route 172.20.0.0 255.255.0.0 192.168.1.2
ip route 172.20.2.0 255.255.255.224 172.20.0.2
ip route 172.20.2.32 255.255.255.240 172.20.0.2
ip route 172.20.2.48 255.255.255.240 172.20.0.2
ip route 172.20.2.64 255.255.255.240 172.20.0.2

end
write memory
```

### En Router INTERMEDIO

Agregar rutas hacia ambas sedes:
```
enable
config t

! Rutas hacia Sede 1
ip route 172.20.0.0 255.255.224.0 172.20.0.1
ip route 172.20.0.0 255.255.255.0 172.20.0.1
ip route 172.20.1.0 255.255.255.240 172.20.0.1

! Rutas hacia Sede 2
ip route 172.20.2.0 255.255.255.224 172.20.0.6
ip route 172.20.2.32 255.255.255.240 172.20.0.6
ip route 172.20.2.48 255.255.255.240 172.20.0.6
ip route 172.20.2.64 255.255.255.240 172.20.0.6

end
write memory
```

### En Router2-S2 (R2-S2)

Agregar rutas hacia Sede 1 y Sede 2:
```
enable
config t

! Rutas hacia Sede 1
ip route 172.20.0.0 255.255.224.0 172.20.0.5
ip route 172.20.0.0 255.255.255.0 172.20.0.5
ip route 172.20.1.0 255.255.255.240 172.20.0.5

! Rutas hacia Sede 2 (su vecino R3-S2)
ip route 172.20.2.0 255.255.255.224 192.168.1.2
ip route 172.20.2.32 255.255.255.240 192.168.1.2
ip route 172.20.2.48 255.255.255.240 192.168.1.2
ip route 172.20.2.64 255.255.255.240 192.168.1.2

end
write memory
```

### En Router3-S2 (R3-S2)

Agregar rutas hacia Sede 1:
```
enable
config t

ip route 172.20.0.0 255.255.224.0 192.168.1.1
ip route 172.20.0.0 255.255.255.0 192.168.1.1
ip route 172.20.1.0 255.255.255.240 192.168.1.1

end
write memory
```

---

## Verificación y Pruebas

### Comandos de verificación en Switches

#### 1. Verificar VLANs creadas
```
show vlan brief
```

Debe mostrar todas las VLANs (10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130)

#### 2. Verificar asignación de interfaces
```
show interfaces switchport
show interfaces FastEthernet0/1 switchport
```

Debe mostrar que cada interfaz está en su VLAN correspondiente

#### 3. Verificar trunk
```
show interfaces trunk
```

Debe mostrar la interfaz FastEthernet0/1 como trunk

### Comandos de verificación en Routers

#### 1. Verificar interfaces
```
show ip interface brief
```

Debe mostrar todas las interfaces UP:
- Interfaces FastEthernet conectadas
- Subinterfaces VLAN con sus IPs

#### 2. Verificar tabla de rutas
```
show ip route
show ip route static
show ip route connected
```

#### 3. Verificar conectividad (Ping)

**Desde R0-S1:**
```
ping 172.20.2.1    ! R3-S2 gateway VLAN 100
ping 172.20.2.33   ! R3-S2 gateway VLAN 110
```

**Desde R1-S1:**
```
ping 172.20.2.1
ping 172.20.0.33   ! R0-S1
```

**Desde Router INTERMEDIO:**
```cisco
ping 172.20.0.33   ! R0-S1
ping 172.20.0.1    ! R1-S1
ping 172.20.2.1    ! R3-S2
```

**Desde PC a PC (entre sedes):**
```
PC5 (Sede 1, VLAN 60) → ping 172.20.2.1 (PC9 Sede 2, VLAN 100)
```

### Verificación de conectividad inter-VLAN

```
! Desde PC en VLAN 10 (172.20.0.x) ping a PC en VLAN 20 (172.20.0.x)
ping 172.20.0.65

! Desde PC en Sede 1 a PC en Sede 2
ping 172.20.2.1
```
---

Esta configuración permite que:
- Los departamentos dentro de la misma sede se comuniquen
- Los departamentos entre diferentes sedes se comuniquen
- Cada VLAN está segmentada y tiene su propio rango de IPs
- Los routers actúan como gateways entre VLANs
