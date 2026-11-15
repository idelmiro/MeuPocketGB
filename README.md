# MeuPocketGB

Sistema enxuto para o **PocketGo (Bittboy, primeira versão)** que liga direto numa
lista com os jogos de **Game Boy e Game Boy Color**. Não tem GMenu2X, outros
emuladores nem menus de configuração do console.

É baseado no [MiyooCFW](https://github.com/MiyooCFW/buildroot) e no emulador
[Gambatte-DMS](https://github.com/tiopex/gambatte-dms). Os dois são open source (GPL-2.0),
e este projeto também é.

## O que muda em relação ao MiyooCFW

| | MiyooCFW | MeuPocketGB |
|---|---|---|
| Tela inicial | GMenu2X | Lista de jogos `.gb` e `.gbc` juntos |
| Emuladores | Dezenas (RetroArch + IPKs) | Só o Gambatte |
| Logo animado no boot | Sim | Não |
| USB (MTP) no boot | Sim | Desligado (dá para religar no `options.cfg`) |
| Save do jogo | Gravado ao sair do emulador | Gravado ~2 s depois que o jogo salva |

O último item importa porque a chave ON/OFF do PocketGo corta a energia na hora.
No Gambatte original, quem desliga sem sair do emulador perde o progresso.
Aqui o save é gravado logo que muda, de forma segura: um arquivo temporário é
gravado e só depois substitui o anterior.

## Dois jeitos de usar

### 1. Modo rápido (cartão que já tem MiyooCFW 2.0)

Não precisa regravar o cartão. Baixe o `meupocketgb-modo-rapido` (em *Releases*
ou nos *Artifacts* da última execução em *Actions*) e siga o
[cartao/LEIA-ME.md](cartao/LEIA-ME.md).

### 2. Imagem completa (o "fork" enxuto)

Uma imagem nova do cartão, compilada só com o necessário. Baixe o
`meupocketgb-...img.gz` e grave num microSD com o **Balena Etcher** ou o **Rufus**
(eles aceitam o `.gz` direto). No primeiro boot aparecem algumas perguntas do
instalador do MiyooCFW: quando ele pedir o modelo, escolha **PocketGo**. Ele ajusta
as partições ao tamanho do cartão e reinicia. Depois disso, copie os jogos
para a partição **ROMS** pelo PC.

## Como os arquivos são gerados

Tudo é compilado pelo GitHub Actions ([.github/workflows/build.yml](.github/workflows/build.yml)):

1. **teste** (minutos): aplica os patches, compila o emulador no PC e roda o teste do save automático.
2. **emulador** (horas na 1ª vez, depois usa cache): compila o SDK estático do MiyooCFW e o Gambatte para o modo rápido.
3. **firmware** (algumas horas): compila a imagem completa com o Buildroot.

Para publicar uma versão, crie uma tag (ex.: `v1.0`): os dois arquivos vão para uma *Release*.

Também dá para compilar num PC com Debian/Ubuntu:

```sh
scripts/build-firmware.sh          # imagem completa
FAZER_SDK=1 scripts/build-emulador.sh   # SDK + binário do modo rápido
```

Num contêiner Ubuntu 22.04 (ex.: `distrobox` no Fedora/Bazzite), instale além das
dependências do workflow: `subversion patch autoconf automake libtool pkg-config gettext texinfo`
(o runner do GitHub já vem com elas).

Depois de mudar um patch em `emulador/patches/`, recompile só o emulador e refaça a imagem
(`-rebuild` **não** reaplica os patches; use `-dirclean`):

```sh
# dentro do contêiner (distrobox enter ...), a partir da raiz do repositório
cd build/buildroot
make BR2_EXTERNAL=$PWD/../../firmware gambatte-meupocketgb-dirclean
make MINIMAL=yes all    # a imagem nova sai como output/images/miyoo-*.img
```

## Se algo der errado

- Se um jogo não abrir, o motivo aparece no topo da lista (ex.: *ROM INVALIDA*) e
  fica anotado no arquivo `meupocketgb-erros.txt`, na partição **ROMS**.
  Se o emulador travar, as últimas mensagens dele também vão para esse arquivo.
- *ROM VAZIA: RECOPIE*: o arquivo está com 0 bytes. No Linux, a partição ext4 grava o
  conteúdo dos arquivos só alguns segundos depois da cópia. Se o cartão sair antes,
  ficam só os nomes. Copie de novo e **ejete** o cartão (ou rode `sync`) antes de tirá-lo.
- A partição ROMS da imagem completa é ext4. No Linux, o sistema libera a escrita
  nela a cada boot. Se o cartão ainda pedir administrador, rode uma vez no terminal:
  `sudo chmod -R a+rwX /run/media/$USER/ROMS`

## Estrutura do repositório

```
emulador/patches/   mudanças no Gambatte-DMS (lista única de ROMs, save automático, teste)
cartao/             arquivos do modo rápido (vão para a partição BOOT)
firmware/           árvore externa do Buildroot (BR2_EXTERNAL)
  configs/meupocketgb.fragment     o que entra e o que sai da imagem
  package/gambatte-meupocketgb/    pacote do emulador
  board/meupocketgb/rootfs/etc/main  script de boot enxuto
  board/meupocketgb/preparar-buildroot.sh  ajustes no MiyooCFW antes de compilar
scripts/            build-firmware.sh e build-emulador.sh
```

As versões do MiyooCFW/buildroot e do Gambatte-DMS ficam fixadas por commit nos
scripts. Para atualizar, troque o commit e confira se o *teste* e o *firmware* passam.

## Situação

- Os patches do Gambatte compilam e foram testados no PC: a lista única aparece e
  o teste do save automático passa.
- A imagem e o binário do modo rápido só existem depois que o GitHub Actions termina.
- Ainda **não foi testado no PocketGo de verdade**. Antes de apagar o cartão atual,
  faça uma cópia dele (ex.: com o *Win32 Disk Imager*) ou use outro microSD.

## Ideias para depois

- Boot ainda mais rápido: tirar mensagens do kernel e o atraso do u-boot.
- Tirar do Gambatte os menus de configuração que não forem usados.
