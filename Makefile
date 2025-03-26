skaffold_prep:
	bash ./skaffold_prepare.sh

build: skaffold_prep
	. ~/.demo_skaffold_env && skaffold build -p demo

dev: skaffold_prep
	. ~/.demo_skaffold_env && skaffold dev -p demo --cleanup=false

run: skaffold_prep
	. ~/.demo_skaffold_env && skaffold run -p demo --cleanup=false

render: skaffold_prep
	. ~/.demo_skaffold_env && skaffold render -p demo

diagnose: skaffold_prep
	. ~/.demo_skaffold_env && skaffold diagnose -p demo


