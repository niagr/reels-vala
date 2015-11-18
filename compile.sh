#!/bin/sh

valac -g --disable-warnings --target-glib=2.32 --thread \
\
	--pkg libsoup-2.4 \
	--pkg json-glib-1.0 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-0.8 \
	--pkg gtk+-3.0 \
	--pkg granite \
	--pkg gdk-pixbuf-2.0 \
\
	./src/Controller.vala \
	./src/AppMain.vala \
	./src/Movie.vala \
	./src/GUIController.vala \
	./src/DetailView.vala \
	./src/MovieItem.vala \
	./src/AsyncMessage.vala \
	./src/MovieInfo.vala \
	./src/ReviewList.vala \
	./src/ViewManager.vala \
	./src/MovieListItem.vala \
	./src/MovieListView.vala \
	./src/MovieListViewItem.vala \
	./src/TMDb/TMDb.vala \
	./src/TMDb/MovieInfo.vala \
	./src/TMDb/Actor.vala \
	./src/TMDb/CrewMember.vala \
	./src/TMDb/Review.vala \
\
-o ./build/reels
