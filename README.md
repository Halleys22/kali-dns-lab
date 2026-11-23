# Laboratorio DNS con BIND 9

Práctica de ciberseguridad de 2.º DAM. Configura una zona DNS autoritativa y usa una política RPZ para bloquear nombres concretos en un resolutor local. La comprobación automatizada valida las respuestas con `dig` y confirma en el registro de BIND que los bloqueos los aplicó la política.

## Probarlo en Kali

Desde la carpeta del repositorio:

```bash
sudo apt update
sudo apt install bind9 bind9-utils dnsutils
bash comprobar.sh
```

El script arranca una instancia temporal de BIND en `127.0.0.1:5300` y la detiene al salir. El puerto 5300 debe estar libre. La instancia usa la configuración del repositorio y las consultas se dirigen explícitamente a ella.

## Qué comprueba

| Consulta | Resultado esperado |
| --- | --- |
| `www.aula.test. A` | `127.0.0.1`, con el indicador de respuesta autoritativa `aa` |
| `aula.test. NS` | `ns1.aula.test.` |
| `bloqueado.test. A` | `NXDOMAIN` aplicado por RPZ |
| `prueba.bloqueado.test. TXT` | `NXDOMAIN` aplicado por la regla de subdominios |

En la práctica original, ejecutada en Kali sobre VirtualBox, se verificó la resolución de `www.aula.test` y el bloqueo del dominio del ejercicio y un subdominio. Esta versión usa `bloqueado.test` para que las consultas de la demostración empleen nombres de prueba.

## Archivos

- `bind/named.conf` limita la escucha y la recursión a la interfaz local y deshabilita las transferencias de zona.
- `bind/db.aula.test` contiene los registros SOA, NS y A.
- `bind/db.rpz-lab` define las dos reglas de bloqueo.
- `comprobar.sh` valida la configuración y prueba las consultas.

Referencias: [apuntes del tema 3 de DAM](https://github.com/carloslobatog/apuntes-dam/blob/main/ciberseguridad/ciber_tema3.html) y [manual de BIND 9](https://bind9.readthedocs.io/en/stable/).
