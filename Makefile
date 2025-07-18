VERSION=0.16.1
NAME=SkyrimNet_SexLab

RELEASE_FILE=versions/SkyrimNet_SexLab ${VERSION}.zip

release: 
	python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	python3 ./python_scripts/info.py -v ${VERSION} -n '${NAME}' -o SkyrimNet_SexLab/info.json
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z -r a '${RELEASE_FILE}' fomod \
	    Scripts \
		README.md \
		SkyrimNet_SexLab.esp \
		fomod/info.json \
		SkyrimNet_SexLab/info.json \
		SkyrimNet_SexLab/group_tags.json \
		SKSE/Plugins/SkyrimNet

group_tags:
	python3 ./python_scripts/group-tags.py animations > SkyrimNet_SexLab/group_tags.json
