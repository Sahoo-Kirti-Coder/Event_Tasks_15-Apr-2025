codeunit 50653 "Delete Processing Checker"
{
    SingleInstance = true;

    var
        stillDeleteProcessing: Boolean;

    procedure isProcessing() processing: Boolean
    begin
        exit(stillDeleteProcessing);
    end;

    procedure setStillProcessingTrueOrFalse(makeTrueOrFalse: Boolean)
    begin
        stillDeleteProcessing := makeTrueOrFalse;
    end;
}