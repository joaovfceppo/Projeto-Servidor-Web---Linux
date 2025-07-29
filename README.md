# Projeto Linux: Infraestrutura Web Segura e Automatizada na AWS

Este repositório documenta a implementação de uma infraestrutura web segura, resiliente e com criação totalmente automatizada na AWS através de User Data. O projeto foi desenvolvido como parte do Programa de Bolsas DevSecOps da Compass UOL e abrange conceitos fundamentais de redes na nuvem, automação de servidores e monitoramento contínuo.

## Visão Geral do Projeto

O desafio consistia em provisionar o ambiente para uma nova aplicação web, garantindo alta disponibilidade e segurança. A solução final inclui uma rede VPC customizada com sub-redes públicas e privadas, um Bastion Host para acesso administrativo seguro, e um servidor web privado que se autoconfigura no lançamento via User Data. Adicionalmente, um script de monitoramento verifica a saúde do site a cada minuto e envia alertas para o Discord em caso de falha.

## Arquitetura Final

A arquitetura implementada segue boas práticas de segurança, minimizando a superfície de ataque ao isolar o servidor web do acesso direto pela internet.

- **VPC (Virtual Private Cloud):** Rede isolada com CIDR `10.0.0.0/16`.
- **Sub-redes Públicas:** Hospedam recursos que precisam de acesso à internet, como o Bastion Host e o NAT Gateway.
- **Sub-redes Privadas:** Hospedam o servidor web, protegendo-o de acessos externos não autorizados.
- **Bastion Host (Jump Server):** Instância EC2 `t2.micro` na sub-rede pública, atuando como um ponto de entrada único e seguro para acesso administrativo (SSH).
- **Servidor Web:** Instância EC2 `t2.micro` na sub-rede privada, configurada automaticamente com Nginx e o script de monitoramento.
- **NAT Gateway:** Permite que o servidor web na sub-rede privada inicie conexões com a internet para baixar pacotes e atualizações.

### Fluxo de Acesso
- **Administrativo (SSH):** O acesso ao servidor web é feito em dois saltos, conectando-se primeiro ao Bastion Host e, a partir dele, ao servidor na rede privada.
- **Público (HTTP):** O acesso ao site é feito através de um túnel SSH (`Local Port Forwarding`) para fins de teste e validação pelo desenvolvedor. Em um ambiente de produção, um Application Load Balancer seria adicionado.

## Passo a Passo da Implementação

### 1. Configuração da Rede (VPC)
A base da infraestrutura foi criada usando o assistente **"VPC e mais"**.
- Foram criadas 2 sub-redes públicas e 2 privadas.
- Um **Internet Gateway** foi associado à tabela de rotas das sub-redes públicas.
- Um **NAT Gateway** foi provisionado em uma sub-rede pública e associado à tabela de rotas das sub-redes privadas, com destino `0.0.0.0/0`.

### 2. Criação das Instâncias (EC2)
Um único par de chaves (`chave-servidor-bastion.pem`) foi criado e utilizado para ambas as instâncias.

- **Bastion Host:**
    - Lançado na **sub-rede pública** com um IP público habilitado.
    - Seu Security Group permite tráfego de entrada na porta `22` (SSH) apenas do IP do administrador.

- **Servidor Web Privado:**
    - Lançado na **sub-rede privada** com IP público desabilitado.
    - Seu Security Group permite tráfego de entrada na porta `22` (SSH) apenas do Bastion e na porta `80` (HTTP) de qualquer lugar.
    - Foi utilizado um script completo no campo **User Data** para automatizar toda a configuração.

### 3. Automação com User Data
O script de automação, executado no primeiro boot do servidor web, realiza as seguintes tarefas:
1.  Atualiza os pacotes do sistema com `apt-get update/upgrade`.
2.  Instala o Nginx.
3.  Habilita e inicia o serviço Nginx.
4.  Cria um arquivo de override no `systemd` para configurar o reinício automático do Nginx em caso de falha (`Restart=on-failure`).
5.  Cria a página `index.html` personalizada em `/var/www/html/`.
6.  Cria o script de monitoramento `monitor.sh` e o torna executável.
7.  Cria o arquivo de log `/var/log/monitoramento.log` e atribui a permissão correta.
8.  Adiciona uma tarefa no `crontab` do usuário `ubuntu` para executar o script de monitoramento a cada minuto.

## Desafios e Soluções

- **Conexão SSH:** O principal desafio foi estabelecer a conexão SSH, que apresentou erros de `Connection timed out` e `Permission denied (publickey)`.
    - A solução para o `timeout` foi corrigir a regra de entrada do Security Group do Bastion para permitir o acesso a partir do IP público correto do administrador.
    - A solução para a `permissão negada` foi garantir o uso de um par de chaves novo e consistente para ambas as instâncias e utilizar o **SSH Agent Forwarding (`-A`)** para "pular" do Bastion para o servidor privado.
- **Falha na Automação:** A primeira versão do script de User Data falhou porque a instância na rede privada não conseguia acessar a internet para baixar pacotes. A solução foi a implementação do **NAT Gateway**.

## Resultados dos Testes

### Teste de Conexão e Acesso ao Site
O acesso ao servidor web privado foi bem-sucedido através do Bastion Host. A visualização do site foi realizada com sucesso através de um túnel SSH (`Local Port Forwarding`), confirmando que o Nginx foi instalado e configurado corretamente pela automação.

![Resultado do site sendo exibido via Túnel SSH](https://storage.googleapis.com/maker-me/media/images/220_29b28666-b337-4d92-bf39-813c015b3c5a.png)
# Projeto Linux: Infraestrutura Web Segura e Automatizada na AWS

Este repositório documenta a implementação de uma infraestrutura web segura, resiliente e totalmente automatizada na AWS. O projeto foi desenvolvido como parte do Programa de Bolsas DevSecOps da Compass UOL e abrange conceitos fundamentais de redes na nuvem, automação de servidores e monitoramento contínuo.

## Visão Geral do Projeto

O desafio consistia em provisionar o ambiente para uma nova aplicação web, garantindo alta disponibilidade e segurança. A solução final inclui uma rede VPC customizada com sub-redes públicas e privadas, um Bastion Host para acesso administrativo seguro, e um servidor web privado que se autoconfigura no lançamento via User Data. Adicionalmente, um script de monitoramento verifica a saúde do site a cada minuto e envia alertas para o Discord em caso de falha.

## Arquitetura Final

A arquitetura implementada segue as melhores práticas de segurança, minimizando a superfície de ataque ao isolar o servidor web do acesso direto pela internet.

- **VPC (Virtual Private Cloud):** Rede isolada com CIDR `10.0.0.0/16`.
- **Sub-redes Públicas:** Hospedam recursos que precisam de acesso à internet, como o Bastion Host e o NAT Gateway.
- **Sub-redes Privadas:** Hospedam o servidor web, protegendo-o de acessos externos não autorizados.
- **Bastion Host (Jump Server):** Instância EC2 `t2.micro` na sub-rede pública, atuando como um ponto de entrada único e seguro para acesso administrativo (SSH).
- **Servidor Web:** Instância EC2 `t2.micro` na sub-rede privada, configurada automaticamente com Nginx e o script de monitoramento.
- **NAT Gateway:** Permite que o servidor web na sub-rede privada inicie conexões com a internet para baixar pacotes e atualizações.

### Fluxo de Acesso
- **Administrativo (SSH):** O acesso ao servidor web é feito em dois saltos, conectando-se primeiro ao Bastion Host e, a partir dele, ao servidor na rede privada.
- **Público (HTTP):** O acesso ao site é feito através de um túnel SSH (`Local Port Forwarding`) para fins de teste e validação pelo desenvolvedor. Em um ambiente de produção, um Application Load Balancer seria adicionado.

## Passo a Passo da Implementação

### 1. Configuração da Rede (VPC)
A base da infraestrutura foi criada usando o assistente **"VPC e mais"**.
- Foram criadas 2 sub-redes públicas e 2 privadas.
- Um **Internet Gateway** foi associado à tabela de rotas das sub-redes públicas.
- Um **NAT Gateway** foi provisionado em uma sub-rede pública e associado à tabela de rotas das sub-redes privadas, com destino `0.0.0.0/0`.

### 2. Criação das Instâncias (EC2)
Um único par de chaves (`chave-servidor-bastion.pem`) foi criado e utilizado para ambas as instâncias.

- **Bastion Host:**
    - Lançado na **sub-rede pública** com um IP público habilitado.
    - Seu Security Group (`sg-bastion`) permite tráfego de entrada na porta `22` (SSH) apenas do IP do administrador.

- **Servidor Web Privado:**
    - Lançado na **sub-rede privada** com IP público desabilitado.
    - Seu Security Group (`sg-web-privado`) permite tráfego de entrada na porta `22` (SSH) apenas do `sg-bastion` e na porta `80` (HTTP) de qualquer lugar.
    - Foi utilizado um script completo no campo **User Data** para automatizar toda a configuração.
 
      <img width="1152" height="648" alt="tela das instancias" src="https://github.com/user-attachments/assets/880bda85-10ef-482e-a220-c2a76d785aad" />


### 3. Automação com User Data
O script de automação, executado no primeiro boot do servidor web, realiza as seguintes tarefas:
1.  Atualiza os pacotes do sistema com `apt-get update/upgrade`.
2.  Instala o Nginx.
3.  Habilita e inicia o serviço Nginx.
4.  Cria um arquivo de override no `systemd` para configurar o reinício automático do Nginx em caso de falha (`Restart=on-failure`).
5.  Cria a página `index.html` personalizada em `/var/www/html/`.
6.  Cria o script de monitoramento `monitor.sh` e o torna executável.
7.  Cria o arquivo de log `/var/log/monitoramento.log` e atribui a permissão correta.
8.  Adiciona uma tarefa no `crontab` do usuário `ubuntu` para executar o script de monitoramento a cada minuto.

<img width="1152" height="648" alt="user dataa" src="https://github.com/user-attachments/assets/0d2ff3e9-6e36-4701-bcaa-33af159c6c2d" />




## Desafios e Soluções

- **Conexão SSH:** O principal desafio foi estabelecer a conexão SSH, que apresentou erros de `Connection timed out` e `Permission denied (publickey)`.
    - A solução para o `timeout` foi corrigir a regra de entrada do Security Group do Bastion para permitir o acesso a partir do IP público correto do administrador.
    - A solução para a `permissão negada` foi garantir o uso de um par de chaves novo e consistente para ambas as instâncias e utilizar o **SSH Agent Forwarding (`-A`)** para "pular" do Bastion para o servidor privado.
- **Falha na Automação:** A primeira versão do script de User Data falhou porque a instância na rede privada não conseguia acessar a internet para baixar pacotes. A solução foi a implementação do **NAT Gateway**.

## Resultados dos Testes

### Teste de Conexão e Acesso ao Site
O acesso ao servidor web privado foi bem-sucedido através do Bastion Host. A visualização do site foi realizada com sucesso através de um túnel SSH (`Local Port Forwarding`), confirmando que o Nginx foi instalado e configurado corretamente pela automação.

<img width="1152" height="648" alt="site localhost" src="https://github.com/user-attachments/assets/47d87a46-1e7f-409f-a4a9-e88851ca8e18" />


### Teste do Sistema de Alerta
O sistema de monitoramento foi testado parando-se o serviço Nginx manualmente (`sudo systemctl stop nginx`).

- **Log do Servidor:** O comando `tail -f /var/log/monitoramento.log` mostrou o registro das verificações de status e a mudança para o estado de `[ALERTA]` quando o serviço foi interrompido.
<img width="1152" height="648" alt="monitoramento site" src="https://github.com/user-attachments/assets/894b0059-6b1a-4d1e-b396-ae3aac4b8fcf" />

- **Alerta no Discord:** As notificações de "OFFLINE" foram recebidas com sucesso no canal do Discord configurado via webhook, validando a funcionalidade do sistema de alerta.
<img width="1152" height="648" alt="discord" src="https://github.com/user-attachments/assets/1eb4576b-f146-4c2d-a351-5a36cdf90bd8" />


### Teste do Sistema de Alerta
O sistema de monitoramento foi testado parando-se o serviço Nginx manualmente (`sudo systemctl stop nginx`).

- **Log do Servidor:** O comando `tail -f /var/log/monitoramento.log` mostrou o registro das verificações de status e a mudança para o estado de `[ALERTA]` quando o serviço foi interrompido.
- **Alerta no Discord:** As notificações de "OFFLINE" foram recebidas com sucesso no canal do Discord configurado via webhook, validando a funcionalidade do sistema de alerta.

![Logs e Alertas no Discord](https://storage.googleapis.com/maker-me/media/images/189_9c1527e0-2521-4874-8b6a-9366dfd90a78.png)
