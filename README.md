# Projeto Linux: Infraestrutura Web Segura e Automatizada na AWS

Este repositório documenta a implementação de uma infraestrutura web segura, resiliente e totalmente automatizada na AWS. O projeto foi desenvolvido como parte do **Programa de Bolsas DevSecOps da Compass UOL** e demonstra habilidades fundamentais em Linux, redes na nuvem, automação e monitoramento.

## Visão Geral do Projeto

O objetivo foi provisionar um ambiente de nuvem para uma nova aplicação web, garantindo alta disponibilidade e segurança. A solução final inclui uma rede VPC customizada com sub-redes públicas e privadas, um Bastion Host para acesso administrativo seguro, e um servidor web privado que se autoconfigura no lançamento via User Data. Adicionalmente, um script de monitoramento verifica a saúde do site a cada minuto e envia alertas para o Discord em caso de falha.

## Etapa 1: Configuração do Ambiente

Nesta etapa, a infraestrutura de base na AWS foi provisionada para garantir um ambiente de rede seguro e isolado.

### 1.1. Criação da VPC (Virtual Private Cloud)
Foi criada uma VPC customizada utilizando o assistente **"VPC e mais"**. A topologia de rede foi desenhada para separar os recursos de acesso público dos recursos privados, uma prática essencial de segurança.

O mapa abaixo ilustra a arquitetura da rede após a criação.

<img width="1588" height="441" alt="mapa de recursos vpc" src="https://github.com/user-attachments/assets/1789a29a-b5b5-46e8-9006-e64f75aa720d" />

A Tabela de Rotas da sub-rede privada foi configurada para direcionar o tráfego de internet (`0.0.0.0/0`) através de um NAT Gateway.

<img width="1626" height="337" alt="tabela de rotas subrede privada" src="https://github.com/user-attachments/assets/6433ac0d-ac31-4e1b-8510-02ec0ef6df99" />

### 1.2. Criação da Instância EC2
Foram criadas duas instâncias (`t2.micro` com Ubuntu), utilizando um único par de chaves para ambas. O Security Group do Servidor Web foi configurado para permitir acesso SSH apenas a partir do Bastion Host.

<img width="1593" height="197" alt="regras de entrada servidor web privado" src="https://github.com/user-attachments/assets/ac138a54-530a-4ded-a2fd-63843241f4d3" />

---

## Etapa 2: Configuração do Servidor Web

Com a infraestrutura de rede pronta, a instalação e configuração do servidor Nginx na instância privada foram totalmente automatizadas via **User Data**. O código completo pode ser encontrado no arquivo [user-data.txt](user-data.txt).

<img width="820" height="514" alt="Automaçao User Data" src="https://github.com/user-attachments/assets/6741908f-34cd-48d6-9dcc-30617e4ccb57" />

---

## Etapa 3: Script de Monitoramento e Webhook

Um script em Bash é executado a cada minuto para verificar a saúde do site, registrar logs e enviar alertas para o Discord em caso de falha. O código completo do script está no arquivo [monitor.sh](monitor.sh).

---

## Etapa 4: Testes e Documentação

Esta seção detalha como validar toda a solução implementada.

### 4.1. Como Testar a Implementação

#### Acesso ao Ambiente
O acesso administrativo ao servidor web privado é feito de forma segura através do Bastion Host, utilizando **SSH Agent Forwarding**. Para visualizar o site, que não possui IP público, um **Túnel SSH (Local Port Forwarding)** é utilizado.

### **Conexão Administrativa:**

<img width="1033" height="770" alt="acesso ao bastion com agent forwarding" src="https://github.com/user-attachments/assets/129de1ff-5e4d-4f13-a7b0-cea0aa58a68d" />

### **Agora acessando o servidor privado a partir do Bastion**





<img width="700" height="566" alt="acesso ao servidor privado" src="https://github.com/user-attachments/assets/f7cc2180-7a9e-4785-a90f-455df45fdf89" />

### **Segundo terminal utilizado para fazer o Tunel SSH (Local Post Forwarding)**

<img width="1018" height="636" alt="segundo terminal para tunel ssh" src="https://github.com/user-attachments/assets/f734613d-878e-4edc-8054-0da310402f47" />

### **Visualização do Site Local que ficou disponível em localhost:8080**
  
<img width="1919" height="1027" alt="Site localhost 80" src="https://github.com/user-attachments/assets/b67d0da1-5248-4b93-bb1a-bb9f4dfac429" />

## Teste do Sistema de Alertas
Para simular uma falha, o serviço Nginx foi parado com `sudo systemctl stop nginx`.

- **Logs de Monitoramento:**

<img width="929" height="696" alt="monitoramento do site" src="https://github.com/user-attachments/assets/bf22f65c-7c8d-46e0-bb7f-95ac56805b39" />

- **Alerta no Discord:**

<img width="1097" height="498" alt="discord novo" src="https://github.com/user-attachments/assets/adc45ad6-5809-4f74-aa37-47316c9fff60" />
