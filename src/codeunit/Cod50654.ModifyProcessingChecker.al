codeunit 50654 "Modify Processing Checker"
{
    SingleInstance = true;

    var
        stillModifyProcessing: Boolean;

    procedure isProcessing() processing: Boolean
    begin
        exit(stillModifyProcessing);
    end;

    procedure setStillProcessingTrueOrFalse(makeTrueOrFalse: Boolean)
    begin
        stillModifyProcessing := makeTrueOrFalse;
    end;

}