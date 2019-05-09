unit txNifs;

interface

uses
  SysUtils;

  // PUBLIC TESTING INTERFACE
  procedure BuildFileHandlingTests;
implementation

uses
  Mahogany,
  txMeta,
{$IFDEF USE_DLL}
  txImports;
{$ENDIF}
{$IFNDEF USE_DLL}
  xeConfiguration, xeNifs, xeMeta;
{$ENDIF}

procedure TestBlockByPath(h: Cardinal);
var
  h1: Cardinal;
begin

end;


procedure BuildFileHandlingTests;
var
  h1, h2, h3: Cardinal;
  len: Integer;
begin
  Describe('Nif File Handling Functions', procedure
    begin
      Describe('LoadNif', procedure
        begin
          Describe('From absolute', procedure
            begin
              It('Should return false with unsupported file', procedure
                begin
                  ExpectFailure(NifLoad(PWideChar(GetDataPath + 'xtest-1.esp'), @h1));
                  Expect(h1 = 0, 'Handle should be NULL.');
                end);

                It('Should return a handle if the filepath is valid', procedure
                  begin
                    ExpectSuccess(NifLoad(PWideChar(GetDataPath + 'xtest-1.nif'), @h1));
                    Expect(h1 > 0, 'Handle should be greater than 0');
                  end);
            end);

          Describe('From data', procedure
            begin
              It('Should return false with file not found', procedure
                begin
                  ExpectFailure(NifLoad(PWideChar('data\file\that\doesnt\exist.nif'), @h2));
                end);
              It('Should return handle of file', procedure
                begin
                  ExpectSuccess(NifLoad(PWideChar('data\xtest-2.nif'), @h2));
                  Expect(h2 > 0, 'Handle should be greater than 0');
                end);

            end);

          Describe('From specific Resource', procedure
            begin
              It('Should return false with unsupported file', procedure
                begin
                  ExpectFailure(NifLoad(PWideChar('Skyrim - Meshes.bsa\file\that\doesnt\exist.nif'), @h3));
                  Expect(h3 = 0, 'Handle should be NULL.');
                end);

              It('Should return a handle if the filepath is valid', procedure
                begin
                  ExpectSuccess(NifLoad(PWideChar('Skyrim - Meshes.bsa\meshes\primitivegizmo.nif'), @h3));
                  Expect(h3 > 0, 'Handle should be greater than 0');
                end);
            end);
      end);

      Describe('Free', procedure
        begin
          It('Should return true.', procedure
            begin
              ExpectSuccess(NifFree(h2));
            end);
          It('Should return false.', procedure
            begin
              ExpectFailure(NifFree(h2));
              h2 := 0;
            end);
          It('Should return true.', procedure
            begin
              ExpectSuccess(NifFree(h3));
            end);
          It('Should return false.', procedure
            begin
              ExpectFailure(NifFree(h3));
              h3 := 0;
            end);
      end);

      Describe('GetName', procedure
        begin
          It('Should return true if file handle is valid', procedure
            begin
              ExpectSuccess(NifGetName(h1, @len));
              ExpectEqual(grs(len), 'NIF');
            end);

        end);

      Describe('BlockByIndex', procedure
      begin
        It('Should return false with invalid block index', procedure
          begin
            ExpectFailure(NifElementByPath(h1, '[9999]', @h2));
            ExpectEqual(h2, 0);
          end);

        It('Should return a TwbNifBlock handle', procedure
          begin
            ExpectSuccess(NifElementByPath(h1, '[41]', @h2));
            Expect(h2 > 0, 'Handle should be greater than 0');
          end);
      end);

      Describe('ElementByPath', procedure
      begin
        It('Should return false with invalid path', procedure
          begin
            ExpectFailure(NifElementByPath(h1, 'Something\that\doesnt\exist', @h3));
            ExpectEqual(h3, 0);
          end);

        It('Should return a TdfElement handle', procedure
          begin
            ExpectSuccess(NifElementByPath(h1, 'Roots\[0]\Children', @h2));
            Expect(h2 > 0, 'Handle should be greater than 0');
          end);
      end);

      Describe('ElementByPathKeywords', procedure
      begin
        It('Roots', procedure
          begin
            ExpectSuccess(NifElementByPath(h1, 'Roots', @h2));
            Expect(h2 > 0, 'Handle should be greater than 0');
            //pointers will be free'd by parent
            h2 := 0;
          end);

        It('Header', procedure
          begin
            ExpectSuccess(NifElementByPath(h1, 'Header', @h2));
            Expect(h2 > 0, 'Handle should be greater than 0');
            //pointers will be free'd by parent
            h2 := 0;
          end);

        It('Footer', procedure
          begin
            ExpectSuccess(NifElementByPath(h1, 'Footer', @h2));
            Expect(h2 > 0, 'Handle should be greater than 0');
          end);
      end);

      Describe('Cleanup', procedure
        begin
          It('Should return true.', procedure
            begin
              ExpectSuccess(NifFree(h1));;
            end);
          It('Should return false as parent handle should free.', procedure
            begin
              ExpectFailure(NifFree(h2));;
            end);
      end);
  end);
end;
end.
