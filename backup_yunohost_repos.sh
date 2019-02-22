#!/bin/bash

# Get the current path
script_dir="$(dirname "$(realpath $0)")"

yunohost_repo="YunoHost"
yunohost_apps_repo="YunoHost-Apps"

clone_repos () {
	git_orga="$1"
	git_dir="$script_dir/$1"
	# Create a directory for each Orga
	mkdir -p "$git_dir"
	( cd "$git_dir"
	# Clean the list of repos
	> $git_orga.list
	page=1
	nb_lines=100
	echo "> List all repositories for the Organization $git_orga"
	# Paginate by 100 repos (can't have more)
	while [ $nb_lines == 100 ]
	do
		# Get the list of repos for each page
		get_git_repos="$(curl --silent --show-error "https://api.github.com/orgs/${git_orga}/repos?per_page=100&page=$page" | grep clone_url | cut -d'"' -f4)"
		# Get the number of repos got of the last curl
		nb_lines=$(echo $get_git_repos | xargs -L1 printf '%s\n' | wc -l)
		# Add the last batch to the complete list of repos
		git_list="$git_dir/$git_orga.list"
		echo "$get_git_repos" >> "$git_list"
		page=$(( $page + 1 ))
	done

	# Sort the list
	sort --output="$git_list" "$git_list"

        echo "> Clone all repositories for the Organization $git_orga"
	while read repo
	do
		if [ ! -d "$git_dir/$(basename --multiple --suffix=.git "$repo")" ]
		then
			git clone "$repo"
		fi
	done < "$git_list"

	echo "> Update all repositories for the Organization $git_orga"
	while read repo
	do
		( cd "$git_dir/$(basename --multiple --suffix=.git "$repo")"
		git pull -a )
	done < "$git_list"
	)
}

clone_repos "${yunohost_repo}"
clone_repos "${yunohost_apps_repo}"
