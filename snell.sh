#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

snell_conf="/root/snell/snell-server.conf"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	#bit=`uname -m`
}

Install_dependency(){
if [[ ${release} == "centos" ]]; then
			yum install unzip wget -y
		else
			apt-get install unzip wget -y
fi
}

Download_snell(){
	mkdir /root/snell
	cd /root/snell
    wget -N --no-check-certificate https://github.com/surge-networks/snell/releases/download/v1.1.1/snell-server-v1.1.1-linux-amd64.zip
    unzip snell*.zip
    mv snell-server snell
    rm -rf snell*.zip
	chmod +x snell
}

Generate_conf(){
	Set_port
	Set_psk
	Set_obfs
}


Deploy_snell(){
	cd /etc/systemd/system
 	cat > snell.service<<-EOF
	[Unit]
	Description=Snell Server
	After=network.target
	[Service]
	ExecStart=/root/snell/snell -c /root/snell/snell-server.conf
	Restart=on-failure
	RestartSec=1s
	[Install]
	WantedBy=multi-user.target
	EOF
	systemctl daemon-reload
	systemctl start snell
	systemctl restart snell
	systemctl enable snell.service
	echo "snell配置信息如下："
	cat /root/snell/snell-server.conf
	echo "snell已安装完毕并运行，请将相应的信息填入surge"
}

Set_port(){
	while true
		do
		echo -e "请输入 Snell 端口 [1-65535]"
		read -e -p "(默认: 6666，回车):" PORT
		[[ -z "${PORT}" ]] && PORT="6666"
		echo $((${PORT}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${PORT} -ge 1 ]] && [[ ${PORT} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	端口 : ${PORT} "
				echo "========================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
		done
}

Set_psk(){
	while true
		do
		echo "请输入 Snell psk（建议随机生成）"
		read -e -p "(避免出错，强烈推荐随机生成，直接回车):" PSK
		if [[ -z "${PSK}" ]]; then
			PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 31)
		else
			[[ ${#PSK} != 31 ]] && echo -e "请输入正确的密匙（31位字符）。" && continue
		fi
		echo && echo "========================"
		echo -e "	psk : ${PSK} "
		echo "========================" && echo
		break
	done
}

Set_obfs(){
	echo "请输入 obfs 混淆( tls / http / 无（直接回车）)"
	read -e -p "(默认：不填):" OBFS
	if [[  -z "${OBFS}" ]]; then
		echo && echo "========================"
		echo -e "	obfs : ${OBFS} "
		echo "========================" && echo
		Write_config
	fi
	if [[ ! -z "${OBFS}" ]]; then
	     echo && echo "========================"
		echo -e "	obfs : ${OBFS} "
		echo "========================" && echo
		Write_config_with_obfs
	fi
}

Write_config(){
	cat > ${snell_conf}<<-EOF
[snell-server]
listen = 0.0.0.0:${PORT}
psk = ${PSK}
EOF
}

Write_config_with_obfs(){
	cat > ${snell_conf}<<-EOF
[snell-server]
listen = 0.0.0.0:${PORT}
psk = ${PSK}
obfs = ${OBFS}
EOF
}

Install_snell(){
	Install_dependency
	Download_snell
	Generate_conf
	Deploy_snell
}

Start_snell(){
	systemctl start snell
	echo "snell已启动"
}

Stop_snell(){
	systemctl stop snell
	echo "snell已停止"
}

Restart_snell(){
	systemctl restart snell
	echo "snell已重启"
}

Check_snell_info(){
	echo "snell配置信息如下："
	cat /root/snell/snell-server.conf
}

Uninstall_snell(){
	systemctl stop snell
	systemctl disable snell
	rm -rf /etc/systemd/snell.service
	rm -rf /root/snell
	echo "snell已经卸载完毕"
}

Change_snell_info(){
	echo -e "修改 snell 配置信息"
	Set_port
	Set_psk
	Set_obfs
	Restart_snell
	echo "修改配置成功"
	echo "你当前的配置为:"
	cat /root/snell/snell-server.conf
}

Update_Shell(){
	rm -rf /root/snell.sh
	cd /root/
	wget --no-check-certificate -O snell.sh https://raw.githubusercontent.com/Newlearner365/sh/master/snell.sh
	chmod +x snell.sh
	echo "snell.sh 已更新至最新版本"
	./snell.sh
}

check_sys
echo -e "       snell 一键管理脚本
  ---- Newlearner365 | My Blog:newlearner.site ----
  
 0. 升级脚本
————————————
 1. 安装 snell（第一次使用）
 2. 启动 snell
 3. 停止 snell
 4. 重启 snell
 5. 查看 snell 配置信息
 6. 修改 snell 配置信息
 7. 卸载 snell
————————————"&&echo
	read -e -p " 请输入数字 [0-7]:" num
	case "$num" in
		0)
		Update_Shell
		;;
		1)
		Install_snell
		;;
		2)
		Start_snell
		;;
		3)
		Stop_snell
		;;
		4)
		Restart_snell
		;;
		5)
		Check_snell_info
		;;
		6)
		Change_snell_info
		;;
		7)
		Uninstall_snell
		;;
		*)
		echo "请输入正确数字 [0-7]"
		;;
	esac 








