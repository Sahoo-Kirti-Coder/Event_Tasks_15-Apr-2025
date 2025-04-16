pageextension 50450 itemCardPageEXT extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Type)
        {
            field("Comment Field"; Rec."Comment Field") { }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}