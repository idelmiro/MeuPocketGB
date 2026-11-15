# MeuPocketGB - lido pelo /etc/main do MiyooCFW (fica em /mnt/autoexec.sh).
# Abre o Gambatte direto na lista de jogos de /roms, sem GMenu2X.

# Desinstalacao: se a pasta meupocketgb sumiu do cartao (particao BOOT),
# apaga este arquivo e deixa o MiyooCFW abrir o GMenu2X normalmente.
if ! test -f /boot/meupocketgb/gambatte-meupocketgb; then
	rm -f "${HOME}/autoexec.sh" "${HOME}/meupocketgb/gambatte-meupocketgb"
	sync
	return 0
fi

export GAMBATTE_ROMDIR=/roms
export FRONTEND=meupocketgb
cd "${HOME}"
# Se o Gambatte fechar ("Quit" no menu dele), grava tudo e abre de novo.
while true; do
	"${HOME}/meupocketgb/gambatte-meupocketgb"
	sync
	sleep 1
done
