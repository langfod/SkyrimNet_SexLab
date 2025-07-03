VERSION=0.8.0
NAME=SkyrimNet_SexLab

RELEASE_FILE=versions/SkyrimNet_SexLab ${VERSION}.zip

release:
	python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z -r a '${RELEASE_FILE}' fomod Scripts fomod\info.json \
		README.md \
		SexLab_SkyrimNet.esp \
	    Scripts \
		SKSE\Plugins\SkyrimNet

