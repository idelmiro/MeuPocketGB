# MeuPocketGB - modo rapido (cartao com MiyooCFW 2.0 ja instalado)
#
# O /etc/main do MiyooCFW roda este arquivo a cada boot, de dentro de /boot.
# Ele liga o daemon (atalhos de volume/brilho, como o original) e instala o
# MeuPocketGB na particao MAIN: o autoexec.sh faz o MiyooCFW abrir o
# Gambatte direto na lista de jogos, no lugar do GMenu2X.
#
# Para voltar ao MiyooCFW normal: apague a pasta "meupocketgb" e este
# arquivo do cartao (particao BOOT) e ligue o console.

daemon >> "${LOGS:-/dev/null}" 2>&1

SRC=/boot/meupocketgb
DST="${HOME:-/mnt}"

if test -f "$SRC/gambatte-meupocketgb" && test -f "$SRC/autoexec.sh"; then
	mkdir -p "$DST/meupocketgb"
	if ! cmp -s "$SRC/gambatte-meupocketgb" "$DST/meupocketgb/gambatte-meupocketgb"; then
		cp "$SRC/gambatte-meupocketgb" "$DST/meupocketgb/gambatte-meupocketgb"
		chmod 0755 "$DST/meupocketgb/gambatte-meupocketgb"
	fi
	if ! cmp -s "$SRC/autoexec.sh" "$DST/autoexec.sh"; then
		cp "$SRC/autoexec.sh" "$DST/autoexec.sh"
	fi
	sync
fi
