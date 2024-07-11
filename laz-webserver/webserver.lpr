program webserver;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  fpwebfile,
  fpmimetypes,
  fphttpapp,
  httproute,
  httpdefs,
  fpjson,
  jsonparser;

const
  MyMime = 'mime.types';

var
  aDir, str: string;
  items: TStringList;
  datafile: string;


  function getListItems(items: TStringList): string;
  var
    s, sID: string;
    item: TStringArray;
    i: integer;
  begin
    Result := '';
    for i := 0 to items.Count - 1 do
    begin
      item := items[i].Split(';');
      sID := IntToStr(i);
      s := '<li ';
      if lowercase(item[1]) = 'true' then
        s := s + 'class="padded completed" '
      else
        s := s + 'class="padded"';
      s := s + '>' + ' <input ' +
        '    type="checkbox"  class="checkbox"                 ' +
        '    id="' + sID + '"                                   ';
      if lowercase(item[1]) = 'true' then
        s := s + 'checked ';

      s := s + '    hx-put="http://localhost:3000/todo/' + sID +
        '"          ' + '    hx-trigger="click"                                      ' +
        '    hx-target="#todo-list"                                  ' +
        '  />                                                        ' +
        '  <label for="' + sID + '">' + item[0] + '</label>      ' +
        '  <button                                               ' +
        '    hx-delete="http://localhost:3000/todo/' + sID + '" ' +
        '    hx-trigger="click"      ' + '    hx-target="#todo-list"' +
        '  >❌</button>' + '</li>';

      Result := Result + s;
    end;
  end;

  procedure getTodoEndpoint(aRequest: TRequest; aResponse: TResponse);
  begin
    aResponse.content := getListItems(items);
    aResponse.Code := 200;
    aResponse.ContentType := 'text/html; charset=utf-8';
    aResponse.ContentLength := length(aResponse.Content);
    aResponse.SendContent;
  end;

  procedure postTodoEndpoint(aRequest: TRequest; aResponse: TResponse);
  var
    newTodo: string;
  begin
    newTodo := aRequest.ContentFields.Values['newTodo'];
    items.Insert(0, newTodo + ';false');
    items.SaveToFile(dataFile);
    aResponse.content := getListItems(items);
    aResponse.Code := 200;
    aResponse.ContentType := 'text/html; charset=utf-8';
    aResponse.ContentLength := length(aResponse.Content);
    aResponse.SendContent;
  end;

  procedure deleteTodoEndpoint(aRequest: TRequest; aResponse: TResponse);
  var
    item: integer;
  begin
    item := StrToInt(ARequest.RouteParams['id']);
    items.Delete(item);
    items.SaveToFile(dataFile);
    aResponse.content := getListItems(items);
    aResponse.Code := 200;
    aResponse.ContentType := 'text/html; charset=utf-8';
    aResponse.ContentLength := length(aResponse.Content);
    aResponse.SendContent;
  end;

  procedure putTodoEndpoint(aRequest: TRequest; aResponse: TResponse);
  var
    item: TStringArray;
    itemid: integer;
  begin
    //get id param
    itemid := StrToInt(ARequest.RouteParams['id']);

    //convert item to array
    item := items[itemid].Split(';');

    //change value for completed
    if lowercase(item[1]) = 'false' then
      item[1]:= 'true'
    else
      item[1] := 'false';

    //move completed items to the bottom
    if lowercase(item[1]) = 'true' then
    begin
      items.Delete(itemid);
      items.add(item[0]+';'+item[1]);
    end;

    //move incompleted items to the top
    if lowercase(item[1]) = 'false' then
    begin
      items.Delete(itemid);
      items.insert(0, item[0]+';'+item[1]);
    end;


    items.SaveToFile(dataFile);

    aResponse.content := getListItems(items);
    aResponse.Code := 200;
    aResponse.ContentType := 'text/html; charset=utf-8';
    aResponse.ContentLength := length(aResponse.Content);
    aResponse.SendContent;
  end;

begin
  MimeTypes.LoadKnownTypes;
  Application.Title := 'HTMX demo server';
  Application.Port := 3000;
  MimeTypesFile := MyMime;
  Application.Initialize;

  //access files from frontend
  aDir := ExtractFilePath(ParamStr(0)) + '..\frontend\';
  aDir := ExpandFileName(aDir);
  RegisterFileLocation('frontend', aDir);
  //persistence the data
  datafile := ExtractFileDir(ParamStr(0)) + '/data/todos.txt';
  items := TStringList.Create;
  items.loadFromFile(dataFile);


  //registering the routes
  HTTPRouter.RegisterRoute('/todo', rmGet, @getTodoEndpoint, False);
  HTTPRouter.RegisterRoute('/todo', rmPost, @postTodoEndpoint, False);
  HTTPRouter.RegisterRoute('/todo/:id', rmDelete, @deleteTodoEndpoint, False);
  HTTPRouter.RegisterRoute('/todo/:id', rmPut, @putTodoEndpoint, False);

  Writeln('open a webbrowser: ' + Application.HostName + ':' + IntToStr(
    Application.port) + '/frontend/index.html');
  Application.Run;

end.
