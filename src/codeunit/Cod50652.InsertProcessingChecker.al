codeunit 50652 "Insert Processing Checker"
{
    SingleInstance = true;

    var
        stillProcessing: Boolean;

    procedure isProcessing() processing: Boolean
    begin
        exit(stillProcessing);
    end;

    procedure setStillProcessingTrueOrFalse(makeTrueOrFalse: Boolean)
    begin
        stillProcessing := makeTrueOrFalse;
    end;

}