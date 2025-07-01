VERSION=0.6.0
NAME=SexLab SkyrimNet

RELEASE_FILE=versions/SexLab SkyrimNet ${VERSION}.zip

release:
	python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z a '${RELEASE_FILE}' fomod Scripts fomod\info.json \
		README.md \
		SexLab_SkyrimNet.esp \
	    Scripts\Source\SexLab_SkyrimNet_Main.psc \
	    Scripts\Source\SexLab_SkyrimNet_PlayerRef.psc \
		SKSE\Plugins\SkyrimNet\prompts\submodules\user_final_instructions
