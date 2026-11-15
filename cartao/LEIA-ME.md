# MeuPocketGB: modo rápido

Use este pacote num cartão que **já tem o MiyooCFW 2.0** funcionando no PocketGo.
Não precisa formatar nada: o MiyooCFW continua instalado, só que abre o
Gambatte direto na lista de jogos em vez do GMenu2X.

## Antes de começar: confira a versão

Coloque o cartão no PC. Na partição pequena chamada **BOOT** precisam existir os
arquivos `options.cfg` e `normalboot.custom.sh-OFF`. Se eles não estiverem lá,
o cartão tem uma versão antiga do MiyooCFW e este modo não funciona; use a
imagem completa (veja o README do projeto).

## Instalação

1. Faça uma cópia de segurança da partição BOOT (é só copiar os arquivos para uma pasta do PC).
2. Copie para a partição **BOOT** o conteúdo da pasta `BOOT` deste pacote:
   o arquivo `normalboot.custom.sh` e a pasta `meupocketgb`.
3. Para o boot ficar mais rápido, abra o `options.cfg` da BOOT num editor de texto e deixe assim:
   - `BOOT_LOGO=0` (sem a animação do logo)
   - `USB_OTG=0` (sem transferência de arquivos pelo cabo USB; o carregamento continua normal)
4. Copie os jogos `.gb` e `.gbc` para a partição **ROMS** (pode ser direto nela ou nas pastas `GB` e `GBC`).
5. Coloque o cartão no PocketGo e ligue. No primeiro boot ele instala o MeuPocketGB e já abre a lista de jogos.

## Controles

- **Lista de jogos:** direcional escolhe, **A** abre o jogo, **B** atualiza a lista.
- **Durante o jogo:** o botão **RESET** da lateral abre o menu do Gambatte
  (save state, trocar de jogo em *Load Game*, configurações).
- **Salvar:** salve normalmente dentro do jogo e espere uns 3 segundos antes de desligar na chave.
  O MeuPocketGB grava o save no cartão sozinho, logo depois que o jogo salva.

## Voltar ao MiyooCFW normal

Apague `normalboot.custom.sh` e a pasta `meupocketgb` da partição BOOT e ligue o console.
Na primeira vez ele ainda passa pelo MeuPocketGB, que se desinstala e abre o GMenu2X.
