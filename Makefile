VERSION=0.14.0
NAME=SkyrimNet_SexLab

RELEASE_FILE=versions/SkyrimNet_SexLab ${VERSION}.zip

release: tag_group
	python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	python3 ./python_scripts/info.py -v ${VERSION} -n '${NAME}' -o SkyrimNet_SexLab/info.json
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z -r a '${RELEASE_FILE}' fomod Scripts fomod\info.json \
		README.md \
		SexLab_SkyrimNet.esp \
		SkyrimNet_SexLab\info.json \
		SkyrimNet_SexLab\tag_group.json \
	    Scripts \
		SKSE\Plugins\SkyrimNet

tag_group:
	python3 ./python_scripts/tags-group.py animations > SkyrimNet_SexLab/tag_group.json
