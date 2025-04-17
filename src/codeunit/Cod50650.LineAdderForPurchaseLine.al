codeunit 50650 "Line Adder For Purchase Line"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterInsertEvent, '', false, false)]
    local procedure insertMethod(var Rec: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        purchaseLine2: Record "Purchase Line";
        item: Record Item;
        insertProcessingChecker: Codeunit "Insert Processing Checker";
    begin
        if insertProcessingChecker.isProcessing() then exit;
        if (Rec.Type = Rec.Type::Item) and (item.Get(Rec."No.")) and (item."Comment Field" <> '') then begin
            PurchaseHeader.Get(Rec."Document Type", Rec."Document No.");
            insertNewSalesLine(Rec."Line No.", PurchaseHeader, item);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterModifyEvent, '', false, false)]
    local procedure modificationProcedure(var Rec: Record "Purchase Line")
    var
        stillModifyProcessing: Codeunit "Modify Processing Checker";
        purchaseLine: Record "Purchase Line";
        item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        if stillModifyProcessing.isProcessing() then
            exit;
        if (Rec."Document Type" <> Rec."Document Type"::Order) or (Rec.Type <> Rec.Type::Item) then
            exit;
        purchaseLine.Reset();
        purchaseLine.SetRange("Document Type", Rec."Document Type");
        purchaseLine.SetRange("Document No.", Rec."Document No.");
        purchaseLine.SetCurrentKey("Attached to Line No.");
        purchaseLine.SetRange("Attached to Line No.", Rec."Line No.");
        if (Rec."No." <> '') and (purchaseLine.IsEmpty) then begin
            if (item.Get(Rec."No.")) and (item."Comment Field" <> '') then begin
                PurchaseHeader.Get(Rec."Document Type", Rec."Document No.");
                purchaseLine.Reset();
                purchaseLine.SetRange("Document Type", Rec."Document Type");
                purchaseLine.SetRange("Document No.", Rec."Document No.");
                purchaseLine.SetFilter("Line No.", '>%1', Rec."Line No.");
                // Message('1');
                //This runs if user modifies lines in between.
                if not purchaseLine.IsEmpty then begin
                    // Message('2');
                    reassignLineNoByIncreasingIt(purchaseLine, PurchaseHeader."No.");
                end;
                // Message('3');
                insertNewSalesLine(Rec."Line No.", PurchaseHeader, item);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterDeleteEvent, '', false, false)]
    local procedure MyProcedure(var Rec: Record "Purchase Line")
    var
        deleteProcessingChecker: Codeunit "Delete Processing Checker";
        purchaseLineToDecareaseLineNo: Record "Purchase Line";
    begin
        if deleteProcessingChecker.isProcessing() then
            exit;

        purchaseLineToDecareaseLineNo.Reset();
        purchaseLineToDecareaseLineNo.SetRange("Document Type", Rec."Document Type");
        purchaseLineToDecareaseLineNo.SetRange("Document No.", Rec."Document No.");
        purchaseLineToDecareaseLineNo.SetFilter("Line No.", '>%1', Rec."Line No.");
        if (not purchaseLineToDecareaseLineNo.IsEmpty) and (Rec.Type = Rec.Type::Item) then begin
            reassignLineNoByDecreasingIt(purchaseLineToDecareaseLineNo, Rec."No.");
        end;
    end;

    local procedure insertNewSalesLine(lastLineNo: Integer; var PurchaseHeader: Record "Purchase Header"; var item: Record Item)
    var
        newPurchaseLine: Record "Purchase Line";
        purchaseLineType: Enum "Purchase Line Type";
    begin
        newPurchaseLine.Init();
        newPurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        newPurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        newPurchaseLine.Validate("Line No.", (lastLineNo + 10000));
        newPurchaseLine.Validate(Type, purchaseLineType::Comment);
        newPurchaseLine.Validate(Description, item."Comment Field");
        newPurchaseLine.Validate("Attached to Line No.", lastLineNo);
        newPurchaseLine.Insert(true);
    end;

    local procedure reassignLineNoByIncreasingIt(var purchaseLine: Record "Purchase Line"; documentNo: Code[20])
    var
        stillModifyProcessing: Codeunit "Modify Processing Checker";
        reassignAttachedToLineNoForPurchaseLine: Record "Purchase Line";
        deletePurchaseLine: Record "Purchase Line";
        newPurchaseLine: Record "Purchase Line";
        insertProcessingChecker: Codeunit "Insert Processing Checker";
        deleteProcessingChecker: Codeunit "Delete Processing Checker";
        lineNumberList: List of [Integer];
        count: Integer;
        i: Integer;
    begin
        Message('Came to reassignLineNoByIncreasingIt');
        purchaseLine.FindSet();
        repeat
            lineNumberList.Add(purchaseLine."Line No.");
        until purchaseLine.Next() = 0;

        lineNumberList.Reverse();
        count := lineNumberList.Count;

        for i := 1 to count do begin
            deletePurchaseLine.Get(deletePurchaseLine."Document Type"::Order, documentNo, lineNumberList.Get(i));
            if deletePurchaseLine.Type = deletePurchaseLine.Type::Comment then begin
                newPurchaseLine.Init();
                newPurchaseLine.Validate("Document Type", deletePurchaseLine."Document Type");
                newPurchaseLine.Validate("Document No.", deletePurchaseLine."Document No.");
                newPurchaseLine.Validate("Line No.", deletePurchaseLine."Line No." + 10000);
                newPurchaseLine.Validate(Type, deletePurchaseLine.Type);
                newPurchaseLine.Validate(Description, deletePurchaseLine.Description);
                newPurchaseLine.Validate("Attached to Line No.", 0);
            end else begin
                newPurchaseLine.TransferFields(deletePurchaseLine);
                newPurchaseLine.Validate("Document Type", deletePurchaseLine."Document Type");
                newPurchaseLine.Validate("Document No.", deletePurchaseLine."Document No.");
                newPurchaseLine.Validate("Line No.", deletePurchaseLine."Line No." + 10000);
            end;
            deleteProcessingChecker.setStillProcessingTrueOrFalse(true);
            deletePurchaseLine.Delete(true);
            insertProcessingChecker.setStillProcessingTrueOrFalse(true);
            if not newPurchaseLine.Insert() then begin
                insertProcessingChecker.setStillProcessingTrueOrFalse(false);
                deleteProcessingChecker.setStillProcessingTrueOrFalse(false);
                Message('Exited');
                exit;
            end;

            if newPurchaseLine.Type <> newPurchaseLine.Type::Comment then begin
                if reassignAttachedToLineNoForPurchaseLine.Get(newPurchaseLine."Document Type", newPurchaseLine."Document No.", newPurchaseLine."Line No." + 10000) then begin
                    if reassignAttachedToLineNoForPurchaseLine.Type = reassignAttachedToLineNoForPurchaseLine.Type::Comment then begin
                        reassignAttachedToLineNoForPurchaseLine.Validate("Attached to Line No.", newPurchaseLine."Line No.");
                        stillModifyProcessing.setStillProcessingTrueOrFalse(true);
                        if not reassignAttachedToLineNoForPurchaseLine.Modify(true) then begin
                            stillModifyProcessing.setStillProcessingTrueOrFalse(false);
                        end;
                        stillModifyProcessing.setStillProcessingTrueOrFalse(false);
                    end;
                end;
            end;

        end;
        for i := count downto 1 do begin
            lineNumberList.RemoveAt(i);
        end;
        insertProcessingChecker.setStillProcessingTrueOrFalse(false);
        deleteProcessingChecker.setStillProcessingTrueOrFalse(false);
        // repeat
        //     newPurchaseLine.TransferFields(purchaseLine);
        //     newPurchaseLine.Validate("Document Type", purchaseLine."Document Type");
        //     newPurchaseLine.Validate("Document No.", purchaseLine."Document No.");
        //     newPurchaseLine.Validate("Line No.", purchaseLine."Line No." + 10000);
        //     deleteProcessingChecker.setStillProcessingTrueOrFalse(true);
        //     purchaseLine.Delete(true);
        //     insertProcessingChecker.setStillProcessingTrueOrFalse(true);
        //     if not newPurchaseLine.Insert() then begin
        //         insertProcessingChecker.setStillProcessingTrueOrFalse(false);
        //         deleteProcessingChecker.setStillProcessingTrueOrFalse(false);
        //         exit;
        //     end;
        // until purchaseLine.Next(-1) = 0;
        // insertProcessingChecker.setStillProcessingTrueOrFalse(false);
        // deleteProcessingChecker.setStillProcessingTrueOrFalse(false);
    end;

    local procedure reassignLineNoByDecreasingIt(var purchaseLine: Record "Purchase Line"; deletedItemNo: Code[20])
    var
        newPurchaseLine: Record "Purchase Line";
        deleteProcessingChecker: Codeunit "Delete Processing Checker";
        insertProcessingChecker: Codeunit "Insert Processing Checker";
        item: Record Item;
        isCommentLineExists: Boolean;
    begin
        isCommentLineExists := (item.Get(deletedItemNo)) and (item."Comment Field" <> '');
        purchaseLine.FindSet();
        repeat
            newPurchaseLine.TransferFields(purchaseLine);
            deleteProcessingChecker.setStillProcessingTrueOrFalse(true);
            purchaseLine.Delete(true);
            newPurchaseLine.Validate("Document Type", purchaseLine."Document Type");
            newPurchaseLine.Validate("Document No.", purchaseLine."Document No.");
            if isCommentLineExists then begin
                newPurchaseLine.Validate("Line No.", purchaseLine."Line No." - 20000);
            end
            else begin
                newPurchaseLine.Validate("Line No.", purchaseLine."Line No." - 10000);
            end;
            insertProcessingChecker.setStillProcessingTrueOrFalse(true);
            if not newPurchaseLine.Insert(true) then begin
                deleteProcessingChecker.setStillProcessingTrueOrFalse(false);
                insertProcessingChecker.setStillProcessingTrueOrFalse(false);
                exit;
            end;
        until purchaseLine.Next() = 0;
        deleteProcessingChecker.setStillProcessingTrueOrFalse(false);
        insertProcessingChecker.setStillProcessingTrueOrFalse(false);
        Message('Reassigning Done');
    end;
}