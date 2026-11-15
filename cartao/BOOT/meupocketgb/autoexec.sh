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
# Se ele travar, as ultimas mensagens vao para ROMS/meupocketgb-erros.txt.
while true; do
	"${HOME}/meupocketgb/gambatte-meupocketgb" > /tmp/gambatte.log 2>&1
	rc=$?
	if test $rc -ne 0; then
		{
			echo "=== Gambatte fechou com codigo $rc ($(date '+%Y-%m-%d %H:%M')) ==="
			tail -n 20 /tmp/gambatte.log
		} >> /roms/meupocketgb-erros.txt 2>/dev/null
	fi
	sync
	sleep 1
done
