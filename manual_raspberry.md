# Instalación de WireGuard en Raspberry Pi

## 1. Obtener credenciales del peer en EC2
1. Conectarse a la instancia:
   ```bash
   ssh -i /ruta/llave.pem ubuntu@EC2_PUBLIC_IP
   ```
2. Listar los peers y localizar el archivo deseado:
   ```bash
   cd /ruta/al/proyecto/wireguard
   ls -la config/peer*
   ```
3. Copiar el archivo del peer (ej. peer1.conf) a tu máquina local:
   ```bash
   scp -i /ruta/llave.pem ubuntu@EC2_PUBLIC_IP:/ruta/al/proyecto/wireguard/config/peer1/peer1.conf .
   ```

## 2. Transferir el peer a la Raspberry Pi
```bash
scp ./peer1.conf pi@RASPBERRY_IP:/home/pi/
```

## 3. Instalar herramientas necesarias
```bash
ssh pi@RASPBERRY_IP
sudo apt update
sudo apt install -y network-manager wireguard-tools
```

## 4. Colocar la configuración
```bash
sudo mv /home/pi/peer1.conf /etc/wireguard/wg0.conf
sudo chown root:root /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
```

## 5. Importar y activar con NetworkManager
```bash
sudo systemctl disable --now wg-quick@wg0 2>/dev/null || true
sudo nmcli connection import type wireguard file /etc/wireguard/wg0.conf
sudo nmcli connection up wg0
```

## 6. Verificar estado
```bash
nmcli connection show wg0
sudo wg
ip a show wg0
```

## 7. Notas adicionales
- Asegurar que EC2 permite UDP 51820 (Security Group y firewall host).
- Si no se requiere gestión de DNS en la Raspberry, eliminar la línea `DNS = ...` antes de importar.
- Para reiniciar la conexión:
  ```bash
  sudo nmcli connection down wg0
  sudo nmcli connection up wg0
  ```