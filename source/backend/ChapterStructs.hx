package backend;

typedef ChapterPage = {
	var visualName:String;
	var name:String;
	@:optional var prevPage:ChapterPage;
	@:optional var nextPage:ChapterPage;
}

typedef Chapter = {
	var name:String;
	var pages:Array<ChapterPage>;
}
