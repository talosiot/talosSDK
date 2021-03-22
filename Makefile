SRC = $(wildcard ./*.ipynb)

it: 
	nbdev_read_nbs
	nbdev_build_lib
	nbdev_clean_nbs
	git status

test:
	nbdev_test_nbs

clean:
	rm -rf dist

github:
	act -P ubuntu-latest=github_workflow_tester

env:
	virtualenv .venv -p python3.8 --prompt "[$(shell basename "`pwd`")] "
	. .venv/bin/activate && pip install jupyter jupyterlab nbdev
	. .venv/bin/activate && (jupyter labextension check @jupyter-widgets/jupyterlab-manager ||  jupyter labextension install @jupyter-widgets/jupyterlab-manager)
	. .venv/bin/activate && pip install -e .

server:
	. .venv/bin/activate && jupyter lab --ip 0.0.0.0
