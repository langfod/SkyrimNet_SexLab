VERSION=0.1.0
NAME=SexLab SkyrimNet

RELEASE_FILE=SexLab SkyrimNet ${VERSION}.zip

release:
	python3 ./p_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z a '${RELEASE_FILE}' fomod Scripts fomod\info.json \
		README.md \
		SexLab_SkyrimNet.esp \
	    Scripts\Source\SexLab_SkyrimNet_Main.psc \
	    Scripts\Source\SexLab_SkyrimNet_PlayerRef.psc \
		SKSE\Plugins\SkyrimNet\prompts\characters\delphine_013485.prompt \
		SKSE\Plugins\SkyrimNet\prompts\characters\nina_FE008894.prompt \
		SKSE\Plugins\SkyrimNet\prompts\components\context\scene_context_full.prompt