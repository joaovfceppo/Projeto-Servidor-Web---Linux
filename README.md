# Projeto Linux: Infraestrutura Web Segura e Automatizada na AWS

Este repositório é um guia passo a passo para a implementação de uma infraestrutura web segura, resiliente e totalmente automatizada na AWS. O projeto foi desenvolvido como parte do **Programa de Bolsas DevSecOps da Compass UOL**.

## Visão Geral da Arquitetura

A solução final consiste em uma infraestrutura segura que isola o servidor de aplicação em uma rede privada, com acesso administrativo controlado por um Bastion Host. A configuração do servidor é totalmente automatizada via User Data.

- **VPC (Virtual Private Cloud):** Rede privada com sub-redes públicas e privadas.
- **Bastion Host (Jump Server):** Ponto de entrada único e seguro para acesso administrativo (SSH).
- **Servidor Web:** Instância EC2 com Nginx em uma sub-rede privada, inacessível diretamente pela internet.
- **NAT Gateway:** Permite que o servidor web privado acesse a internet para atualizações.
- **Monitoramento:** Script em Bash que verifica a saúde do site a cada minuto e envia alertas para o Discord.

## Pré-requisitos

Antes de começar, garanta que você tenha:

1.  Uma **conta na AWS** com as devidas permissões para criar os recursos descritos.
2.  **WSL (Subsistema do Windows para Linux)** instalado e configurado em sua máquina local. Ele é essencial para o acesso SSH e gerenciamento de chaves.
    - Para instalar, abra o PowerShell como Administrador e execute: `wsl --install`. Após a instalação, reinicie o computador e configure um usuário/senha para a sua distribuição Linux (como o Ubuntu). Para mais detalhes, consulte a [documentação oficial da Microsoft](https://learn.microsoft.com/pt-br/windows/wsl/install).
3.  Uma **URL de Webhook** de um canal do Discord (ou Slack/Telegram) para receber os alertas.

---

## a. Como Configurar o Ambiente

Nesta seção, vamos criar a infraestrutura de base na AWS.

### 1. Criar a Rede (VPC)
Acesse o console da AWS e crie uma VPC utilizando o assistente **"VPC e mais"**.

- **Configurações:**
    - **Nome:** `projeto-linux-vpc` (sugestão)
    - **Número de Zonas de Disponibilidade:** `2`
    - **Número de sub-redes públicas:** `2`
    - **Número de sub-redes privadas:** `2`
    - **Gateways NAT:** `1` (em 1 AZ)
    - **Endpoints da VPC:** S3 Gateway

Após a criação, a topologia da rede estará pronta.

<p align="center">
  <img src="https://github.com/user-attachments/assets/1789a29a-b5b5-46e8-9006-e64f75aa720d" alt="mapa de recursos vpc" width="800">
  <br>
  <i>Figura 1: Mapa de Recursos da VPC gerado pelo assistente.</i>
</p>

### 2. Configuração do NAT Gateway
Durante a fase de automação, foi identificado que a instância na sub-rede privada não conseguia acessar a internet para baixar pacotes, fazendo o script User Data falhar. A solução foi configurar um NAT Gateway.

**Passos da Configuração Manual:**

1.  **Criar o Gateway NAT:**
    - No console da VPC, em **"Gateways NAT"**, um novo gateway foi criado.
    - **Nome:** `meu-Nat-Gateway`.
    - **Sub-rede:** Foi selecionada uma **sub-rede pública**.
    - **IP Elástico:** Um novo IP Elástico foi alocado para o gateway.

2.  **Configurar a Tabela de Rotas Privada:**
    - Em **"Tabelas de Rotas"**, a tabela associada à sub-rede privada foi selecionada.
    - Uma nova rota foi adicionada para direcionar todo o tráfego de internet (`0.0.0.0/0`) para o NAT Gateway recém-criado.

<p align="center">
  <img src="https://github.com/user-attachments/assets/6433ac0d-ac31-4e1b-8510-02ec0ef6df99" alt="tabela de rotas subrede privada" width="800">
  <br>
  <i>Figura 2: Tabela de Rotas da sub-rede privada com a rota para o NAT Gateway.</i>
</p>

### 3. Criar as Instâncias EC2
Crie um único par de chaves para ser utilizado em ambas as instâncias.

- **Bastion Host:**
    - **Ação:** Inicie uma nova instância EC2 `t2.micro` com Ubuntu.
    - **Localização:** Na **sub-rede pública** com IP público habilitado.
    - **Par de Chaves:** Crie um novo par de chaves (ex: `chave-projeto.pem`) e salve o arquivo `.pem`. (Eu utilizei 'chave-servidor-bastion.pem').
    - **Security Group:** Crie um grupo (`sg-bastion`) permitindo tráfego na porta `22` (SSH) **apenas do seu IP**.

- **Servidor Web Privado:**
    - **Ação:** Inicie uma segunda instância EC2 `t2.micro` com Ubuntu.
    - **Localização:** Na **sub-rede privada** com IP público desabilitado.
    - **Par de Chaves:** **Reutilize o par de chaves** criado para o Bastion.
    - **Security Group:** Crie um grupo (`sg-web-privado`) com duas regras de entrada:
        1.  Porta `22` (SSH) permitida apenas a partir do Security Group do Bastion (`sg-bastion`).
        2.  Porta `80` (HTTP) permitida de qualquer lugar (`0.0.0.0/0`).

<p align="center">
  <img src="https://github.com/user-attachments/assets/ac138a54-530a-4ded-a2fd-63843241f4d3" alt="regras de entrada servidor web privado" width="800">
  <br>
  <i>Figura 3: Regras de entrada do Security Group do Servidor Web.</i>
</p>

---

## b. Como Instalar e Configurar o Servidor Web
**Esta seção descreve a configuração manual. A versão automatizada está na seção "Desafio Bônus"**

Após a criação das instâncias, conecte-se ao **servidor web privado** (através do Bastion) para realizar a configuração completa do ambiente.

### 1. Instalação do Nginx
Primeiro, atualize os pacotes do sistema e instale o Nginx com os seguintes comandos:
```bash
# Atualiza a lista de pacotes e os pacotes existentes
sudo apt update && sudo apt upgrade -y

# Instala o Nginx
sudo apt install nginx -y
```

### 2. Criação da Página HTML
Crie uma página de exemplo para ser exibida pelo servidor. O conteúdo completo do HTML pode ser encontrado no arquivo [index.html](https-github.com-joaovfceppo-Projeto-Servidor-Web---Linux-blob-main-index.html).
```bash
# Abre o editor de texto para criar/editar a página
sudo nano /var/www/html/index.html
```
Após colar o conteúdo do arquivo `index.html` no editor, salve e saia (`Ctrl+X`, `Y`, `Enter`).

### 3. Configuração de Resiliência (systemd)
Para garantir que o Nginx reinicie automaticamente em caso de falha, configure o serviço `systemd`:
```bash
# Abre um arquivo de override para o serviço Nginx
sudo systemctl edit nginx
```
Dentro do editor, insira o seguinte conteúdo e salve:
```ini
[Service]
Restart=on-failure
RestartSec=5s
```
Para aplicar a nova regra, execute:
```bash
sudo systemctl daemon-reload
sudo systemctl restart nginx
```

### 4. Criação do Script de Monitoramento
Crie o script que irá monitorar o site. O código completo está no arquivo [monitor.sh](https-github.com-joaovfceppo-Projeto-Servidor-Web---Linux-blob-main-monitor.sh).
```bash
# Crie um diretório para o script na pasta home do usuário
mkdir ~/scripts
# Crie e edite o arquivo de script
nano ~/scripts/monitor.sh
```
Cole o conteúdo do arquivo `monitor.sh` no editor e substitua a URL do webhook pela sua. Salve e saia.

### 5. Automação do Monitoramento (Cron)
Para que o script de monitoramento seja executado a cada minuto, siga estes passos:
```bash
# Torne o script executável
chmod +x ~/scripts/monitor.sh

# Crie o arquivo de log e dê a permissão correta para o usuário 'ubuntu'
sudo touch /var/log/monitoramento.log
sudo chown ubuntu:ubuntu /var/log/monitoramento.log

# Abra o editor de tarefas agendadas do usuário atual
crontab -e
```
Adicione a seguinte linha no final do arquivo e salve para que a tarefa seja agendada:
```
* * * * * /home/ubuntu/scripts/monitor.sh
```

## c. Como Funciona o Script de Monitoramento
**A implementação manual deste script segue os mesmos passos da versão automatizada**

O monitoramento é realizado por um script em Bash, cujo código está no arquivo [monitor.sh](https-github.com-joaovfceppo-Projeto-Servidor-Web---Linux-blob-main-monitor.sh). Ele é agendado pelo `cron` para rodar a cada minuto e possui as seguintes funcionalidades:
- **Verificação:** Usa `curl` para checar o status HTTP do site em `localhost`.
- **Logging:** Registra todas as verificações no arquivo `/var/log/monitoramento.log`.
- **Alerta:** Em caso de falha (status diferente de 200), envia um alerta para o Discord via webhook.

---

## d. Como Testar e Validar a Solução

### 1. Acesso ao Ambiente

- **Acesso Administrativo:** Para gerenciar o servidor privado, conecte-se primeiro ao Bastion com SSH Agent Forwarding e, de lá, "pule" para o servidor privado.
  
  ```bash
  # No seu terminal local (WSL), adicione sua chave ao agente
  eval "$(ssh-agent -s)"
  ssh-add /caminho/para/sua/chave.pem
  
  # Conecte-se ao Bastion com Agent Forwarding ativado
  ssh -A ubuntu@IP_PUBLICO_DO_BASTION
  
  # Uma vez dentro do Bastion, pule para o servidor privado
  ssh ubuntu@IP_PRIVADO_DO_SERVIDOR_WEB
  ```
  <p align="center">
    <img src="https://github.com/user-attachments/assets/129de1ff-5e4d-4f13-a7b0-cea0aa58a68d" alt="acesso ao bastion com agent forwarding" width="800">
    <br>
    <i>Figura 5: Conexão ao Bastion com Agent Forwarding ativado.</i>
  </p>
  <p align="center">
    <img width="700" height="566" alt="acesso ao servidor privado" src="https://github.com/user-attachments/assets/f7cc2180-7a9e-4785-a90f-455df45fdf89" />
    <br>
    <i>Figura 6: "Pulo" do Bastion para o Servidor Web Privado.</i>
  </p>

- **Visualização do Site:** Para visualizar o site em um navegador, crie um Túnel SSH em um **novo terminal local**.
  
  ```bash
  ssh -i /caminho/para/sua/chave.pem -L 8080:IP_PRIVADO_DO_SERVIDOR_WEB:80 ubuntu@IP_PUBLICO_DO_BASTION
  ```
  <p align="center">
    <img src="https://github.com/user-attachments/assets/f734613d-878e-4edc-8054-0da310402f47" alt="segundo terminal para tunel ssh" width="800">
    <br>
    <i>Figura 7: Comando para criar o túnel SSH.</i>
  </p>
  
  Após executar, acesse `http://localhost:8080` no seu navegador.
  
  <p align="center">
    <img src="https://github.com/user-attachments/assets/b67d0da1-5248-4b93-bb1a-bb9f4dfac429" alt="Site localhost 80" width="800">
    <br>
    <i>Figura 8: Site exibido com sucesso no navegador local via túnel.</i>
  </p>

### 2. Teste do Sistema de Alerta

1.  Acesse o servidor web privado (seguindo os passos de Acesso Administrativo).
2.  Para simular uma falha, pare o serviço Nginx com o comando:
    ```bash
    sudo systemctl stop nginx
    ```
3.  Aguarde até um minuto e verifique os resultados.

- **Logs de Monitoramento:**
  Você pode acompanhar os logs em tempo real para ver a mudança de status.
  ```bash
  tail -f /var/log/monitoramento.log
  ```
  <p align="center">
    <img src="https://github.com/user-attachments/assets/bf22f65c-7c8d-46e0-bb7f-95ac56805b39" alt="monitoramento do site" width="800">
    <br>
    <i>Figura 9: Log do script mostrando a mudança de status de [INFO] para [ALERTA].</i>
  </p>

- **Alerta no Discord:**
  Uma notificação de "OFFLINE" deve ser recebida instantaneamente no canal configurado.
  <p align="center">
    <img src="https://github.com/user-attachments/assets/adc45ad6-5809-4f74-aa37-47316c9fff60" alt="discord novo" width="800">
    <br>
    <i>Figura 10: Notificação de "OFFLINE" recebida no Discord.</i>
  </p>
  
  Para restaurar o serviço, execute `sudo systemctl start nginx`.

---

## Desafio Bônus Implementado: Automação com User Data

Para otimizar o processo de provisionamento, a configuração manual descrita na **seção b** foi totalmente automatizada utilizando um script no campo **User Data** da instância do servidor web. Este método garante que a instância já inicie com todo o ambiente configurado.

O script é inserido durante a criação da instância, na seção **"Detalhes avançados" -> "Dados do usuário"**.

O código completo utilizado para a automação pode ser encontrado no arquivo [user-data.txt](https-github.com-joaovfceppo-Projeto-Servidor-Web---Linux-blob-main-user-data.txt).

<p align="center">
  <img src="https://github.com/user-attachments/assets/6741908f-34cd-48d6-9dcc-30617e4ccb57" alt="Automaçao User Data" width="800">
  <br>
  <i>Figura 4: Script de automação inserido no campo User Data durante a criação da instância.</i>
</p>

---
## Desafios Encontrados e Soluções

- **`Connection timed out` em Conexão SSH:** O problema mais recorrente foi o de timeout ao tentar conectar ao Bastion. A causa era a mudança do IP público do administrador, que não correspondia mais à regra de entrada do Security Group. A solução foi editar a regra e inserir manualmente o IP público atual.

- **`Permission denied (publickey)`:** Este erro ocorreu por uma confusão com pares de chaves reutilizados de instâncias antigas. A solução definitiva foi criar um único e **novo par de chaves** e usá-lo consistentemente tanto para o Bastion quanto para o servidor web, além de usar **SSH Agent Forwarding (`-A`)**.

- **Falha na Automação com User Data:** A primeira tentativa de automação falhou porque a instância na rede privada não conseguia acessar a internet para baixar pacotes. A solução foi a implementação e configuração manual do **NAT Gateway** e da tabela de rotas da sub-rede privada.
