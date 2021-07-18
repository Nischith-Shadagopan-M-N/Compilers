%union {
    struct node* snod;
}

%token ID INTCONST FLOATCONST 
%token PRINTF FRMT_SPEC
%token OROP ANDOP EQOP NEQOP GEQOP COMOP LEQOP POIOP DECOP INCOP SIZEOF 
%token BREAK CASE CONTINUE DEFAULT DO ELSE EXTERN FLOAT IF INT RETURN STRUCT SWITCH VOID WHILE
%token LBRACKET RBRACKET LBRACES RBRACES LCURLY RCURLY DOT AND STAR ADD SUB NOT DIV MOD LESSER GREATER SEMICOLON EQUAL COMMA COLON

%type <snod> program decl_list decl struct_decl var_decl type_spec extern_spec func_decl params param_list param stmt_list stmt while_stmt dowhile_stmt print_stmt format_specifier compound_stmt local_decls local_decl if_stmt return_stmt break_stmt continue_stmt switch_stmt compound_case single_case default_case assign_stmt incr_stmt decr_stmt expr Pexpr arg_list args integerLit floatLit identifier

%{
    #include <bits/stdc++.h>
    using namespace std;
    #define TEXT(a) #a

	void yyerror(char *);
	int yylex(void);
	char mytext[100];
    int syntax = 0;
    extern char *yytext;
    long long int astlp = 0;
    long long int iflp = 0;
    long long int whilelp = 0;
    long long int switchlp = 0;
    long long int mainlp = 0;
    long long int offs = 0;
    long long int npara = 0;
    long long int narg = 0;
    int retu = 1;
    unordered_map < string, long long int > symtab;
    unordered_map < string, long long int > funtab;
    unordered_map < string, long long int > paramtab;
    unordered_map < string, long long int > arraysize;
    
    enum ntype{
        program,
        decl_list,
        decl,
        struct_decl,
        var_decl,
        type_spec,
        extern_spec,
        func_decl,
        params,
        param_list,
        param,
        stmt_list,
        stmt,
        expr_stmt,
        while_stmt,
        dowhile_stmt,
        print_stmt,
        format_specifier,
        compound_stmt,
        local_decls,
        local_decl,
        if_stmt,
        return_stmt,
        break_stmt,
        continue_stmt,
        switch_stmt,
        compound_case,
        single_case,
        default_case,
        assign_stmt,
        incr_stmt,
        decr_stmt,
        expr,
        Pexpr,
        arg_list,
        args,
        integerLit,
        floatLit,
        identifier,
        lcurly,
        rcurly,
        semicolon,
        comma,
        lbracket,
        rbracket,
        dot,
        lbraces,
        rbraces,
        star,
        Equal,
        colon,
        Greater,
        lesser,
        add,
        sub,
        Div,
        mod,
        Not,
        And,
        id,
        intconst,
        floatconst, 
        Printf, 
        frmt_spec,
        orop, 
        andop, 
        eqop, 
        neqop, 
        geqop, 
        comop, 
        leqop, 
        poiop, 
        decop, 
        incop, 
        Sizeof, 
        Break, 
        Case, 
        Continue, 
        Default, 
        Do, 
        Else, 
        Extern, 
        Float, 
        If, 
        Int, 
        Return, 
        Struct, 
        Switch, 
        Void, 
        While,
        epsilon
    };
    #define ArithB (node->nt == add || node->nt == sub || node->nt == star || node->nt == Div || node->nt == mod)
    #define Bin (node->nt == orop || node->nt == andop)
    #define RelB (node->nt == lesser || node->nt == Greater || node->nt == leqop || node->nt == geqop || node->nt == eqop || node->nt == neqop)

    string typenam[] = {"program", "decl_list", "decl", "struct_decl", "var_decl", "type_spec", "extern_spec", "func_decl", "params", "param_list", "param", "stmt_list", "stmt", "expr_stmt", "while_stmt", "dowhile_stmt", "print_stmt", "format_specifier", "compound_stmt", "local_decls", "local_decl", "if_stmt", "return_stmt", "break_stmt", "continue_stmt", "switch_stmt", "compound_case", "single_case", "default_case", "assign_stmt", "incr_stmt", "decr_stmt", "expr", "Pexpr", "arg_list", "args", "integerLit", "floatLit", "identifier", "lcurly", "rcurly", "semicolon", "comma", "lbracket", "rbracket", "dot", "lbraces", "rbraces", "imull", "Equal", "colon", "setg", "setl", "addl", "subl", "idivl", "idivl", "Not", "And", "id", "intconst", "floatconst", "Printf", "frmt_spec", "addl", "imull", "sete", "setne", "setge", "comop", "setle", "poiop", "decop", "incop", "Sizeof", "Break", "Case", "Continue", "Default", "Do", "Else", "Extern", "Float", "If", "Int", "Return", "Struct", "Switch", "Void", "While", "epsilon"};

    struct node{
        enum ntype nt;
        struct node* children[9];
        int nchild;
        string str;
        long long int offset;
        long long int height;
        long long int lp;
    };

    long long int max(long long int num1, long long int num2){
        return (num1 > num2 ) ? num1 : num2;
    }

    struct node* cons_lexstr(enum ntype a, string sr){
        //printf("malloc1\n");
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = a;
        newnode->nchild = 0;
        for(int i=0; i<9;i++){
            newnode->children[i] = NULL;
        }
        newnode->str = sr;
        newnode->height = 1;
        newnode->lp = 1;
        //printf("%s, %lld\n", typename[a], newnode->height);
        return newnode;
    }

    struct node* cons_lex(enum ntype a){
        //printf("malloc2\n");
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = a;
        newnode->nchild = 0;
        for(int i=0; i<9;i++){
            newnode->children[i] = NULL;
        }
        newnode->height = 1;
        newnode->lp = 1;
        //printf("%s, %lld\n", typename[a], newnode->height);
        return newnode;
    }

    struct node* cons_rep(enum ntype typ, int c, struct node* nodarr[]){
        //printf("malloc3\n");
        struct node* nod = (struct node*) malloc(sizeof(struct node));
        nod->nt = typ;
        nod->nchild = c;
        //printf("malloc4\n");
        for(int i=0; i<c; i++){
            nod->children[i] = nodarr[i];
        }
        long long int maxlp = 0;
        long long int maxh = 0;
        long long int smaxh = 0;
        for(int i=0; i<c; i++){
            maxlp = max(maxlp, nodarr[i]->lp);
            if((nodarr[i]->height)>maxh){
                smaxh = maxh;
                maxh = (nodarr[i]->height);
            }
            else{
                if((nodarr[i]->height)>smaxh){
                    smaxh = (nodarr[i]->height);
                }
            }
        }
        nod->height = maxh + 1;
        nod->lp = max(maxlp, maxh+smaxh+1);
        //printf("%s, %lld\n", typename[typ], nod->height);
        if(typ==program){
            astlp = nod->lp;
        }
        if(typ==if_stmt){
            iflp = max(iflp, nod->lp);
        }
        if(typ==while_stmt){
            whilelp = max(whilelp, nod->lp);
        }
        if(typ==switch_stmt){
            switchlp = max(switchlp, nod->lp);
        }
        if(typ==func_decl && (nodarr[1]->children[0]->str == "main")){
            mainlp = max(mainlp, nod->lp);
        }
        return nod;
    }

    void genconst(string s){
        cout<<"movl $"<<s<<", %eax"<<endl;
    }

    void push(string s){
        cout<<"pushq %"<<s<<endl;
    }

    void pop(string s){
        cout<<"popq %"<<s<<endl;
    }

    void pushl(string s){
        cout<<"subq $4, %rsp"<<endl;
        cout<<"movl "<<s<<", (%rsp)"<<endl;
    }

    void popl(string s){
        cout<<"movl (%rsp), "<<s<<endl;
        cout<<"addq $4, %rsp"<<endl;
    }

    string isidentifier(struct node* nod){
        if(nod->nt == identifier){
            return nod->children[0]->str;
        }
        else if(nod->nt == Pexpr && nod->nchild == 3){
            return isidentifier(nod->children[1]);
        }
        else if(nod->nt == expr && nod->nchild == 1){
            return isidentifier(nod->children[0]);
        }
        else{
            return "";
        }
    }

    long long int coun = 0;
    string uniqlabel(string s){
        s = s + to_string(coun);
        coun++;
        return s;
    }

    string getpara(long long int i){
        if(i==0){
            return "%edi";
        }
        else if(i==1){
            return "%esi";
        }
        else if(i==2){
            return "%edx";
        }
        else if(i==3){
            return "%ecx";
        }
        else if(i==4){
            return "%r8d";
        }
        else if(i==5){
            return "%r9d";
        }
        else {
            return "-" + to_string((i-3)*4) + "(%rbp)";
        }
    }

    void genlabel(string s){
        cout<<s<<":"<<endl;
    } 

    void gotol(string s){
        cout<<"jmp "<<s<<endl;
    }

    void enter(){
        cout<<"endbr64"<<endl;
        push("rbp");
        cout<<"movq %rsp, %rbp"<<endl;
    }

    void codegen(struct node* node){
        //cout<<typenam[node->nt]<<endl;
        if(ArithB){
            codegen(node->children[0]);
            pushl("%eax");
            //cout<<3<<endl;
            codegen(node->children[1]);
            cout<<"movl %eax, %ebx"<<endl;
            popl("%eax");
            if(node->nt == mod || node->nt == Div){
                cout<<"cltd"<<endl;
                cout<<typenam[node->nt]<<" %ebx"<<endl;
            }
            else{
                cout<<typenam[node->nt]<<" %ebx, %eax"<<endl;
            }
            if(node->nt == mod){
                cout<<"movl %edx, %eax"<<endl;
            }
        }
        else if(node->nt == incr_stmt){
            if(symtab.find(node->children[0]->children[0]->str) != symtab.end()){
                cout<<"incl -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp)"<<endl;
            }
            else{
                cout<<"incl "<<getpara(paramtab[node->children[0]->children[0]->str])<<endl;
            }
        }
        else if(node->nt == decr_stmt){
            if(symtab.find(node->children[0]->children[0]->str) != symtab.end()){
                cout<<"decl -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp)"<<endl;
            }
            else{
                cout<<"decl "<<getpara(paramtab[node->children[0]->children[0]->str])<<endl;
            }
        }
        else if(RelB){
            codegen(node->children[0]);
            pushl("%eax");
            //cout<<4<<endl;
            codegen(node->children[1]);
            popl("%ebx");
            cout<<"cmpl %eax, %ebx"<<endl;
            cout<<typenam[node->nt]<<" %al"<<endl;
            cout<<"movzbl %al, %eax"<<endl;
        }
        else if(Bin){
            codegen(node->children[0]);
            cout<<"cmpl $0, %eax"<<endl;
            cout<<"setne %al"<<endl;
            cout<<"movzbl %al, %eax"<<endl;
            string lae = uniqlabel("end");
            if(node->nt == orop){
                cout<<"cmpl $0, %eax"<<endl;
                cout<<"jne "<<lae<<endl;
            }
            else{
                cout<<"cmpl $0, %eax"<<endl;
                cout<<"je "<<lae<<endl;
            }
            pushl("%eax");
            //cout<<5<<endl;
            codegen(node->children[1]);
            popl("%ebx");
            cout<<"cmpl $0, %eax"<<endl;
            cout<<"setne %al"<<endl;
            cout<<"movzbl %al, %eax"<<endl;
            cout<<typenam[node->nt]<<" %ebx, %eax"<<endl;
            cout<<"cmpl $0, %eax"<<endl;
            cout<<"setg %al"<<endl;
            cout<<"movzbl %al, %eax"<<endl;
            genlabel(lae);
        }
        else if(node->nt == expr){
            if(node->nchild == 2){
                codegen(node->children[1]);
                if(node->children[0]->nt == sub){
                    cout<<"negl %eax"<<endl;
                }
                else if(node->children[0]->nt == Not){
                    cout<<"cmpl $0, %eax"<<endl;
                    cout<<"sete %al"<<endl;
                    cout<<"movzbl %al, %eax"<<endl;
                }
            }
            else if(node->nchild == 4){
                if(node->children[1]->nt == lbraces && node->children[0]->nt != Sizeof){
                    narg = funtab[node->children[0]->children[0]->str];
                    int temp = funtab[node->children[0]->children[0]->str];
                    codegen(node->children[2]);
                    cout<<"call "<<node->children[0]->children[0]->str<<endl;
                    for(int i = 0; i<min(temp, 6); i++){
                        popl(getpara(i));
                    }
                    if(temp>6){
                        cout<<"addq "<<"$"<<4*(temp - 6)<<", %rsp"<<endl;
                    }
                }
                else if(node->children[1]->nt == lbracket){
                    codegen(node->children[2]);
                    cout<<"movl -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp, %rax, 4), %eax"<<endl;
                }
                else{
                    string name = isidentifier(node->children[2]);
                    if(arraysize.find(name) != arraysize.end()){
                        cout<<"movl $"<<arraysize[name]<<", %eax"<<endl;
                    }
                    else{
                        cout<<"movl $4, %eax"<<endl;
                    }
                }
            }
            else{
                goto rest;
            }
        }
        else if(node->nt == if_stmt){
            if(node->nchild == 5){
                string laf = uniqlabel("false");
                codegen(node->children[2]);
                cout<<"cmpl $0, %eax"<<endl;
                cout<<"je "<<laf<<endl;
                codegen(node->children[4]);
                cout<<laf<<":"<<endl;
            }
            else{
                string laf = uniqlabel("false");
                string lae = uniqlabel("end");
                codegen(node->children[2]);
                cout<<"cmpl $0, %eax"<<endl;
                cout<<"je "<<laf<<endl;
                codegen(node->children[4]);
                cout<<"jmp "<<lae<<endl;
                cout<<laf<<":"<<endl;
                codegen(node->children[6]);
                cout<<lae<<":"<<endl;
            }
        }
        else if(node->nt == while_stmt){
            string start = uniqlabel("start");
            string end = uniqlabel("end");
            genlabel(start);
            string laf = uniqlabel("false");
            codegen(node->children[2]);
            cout<<"cmpl $0, %eax"<<endl;
            cout<<"je "<<laf<<endl;
            codegen(node->children[4]);
            gotol(start);
            cout<<laf<<":"<<endl;
        }
        else if(node->nt == Equal){
            if(node->nchild == 2){
                codegen(node->children[1]);
                if(symtab.find(node->children[0]->children[0]->str) != symtab.end()){
                    //cout<<child->str<<endl;
                    cout<<"movl %eax, -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp)"<<endl;
                }
                else{
                    cout<<"movl %eax, "<<getpara(paramtab[node->children[0]->children[0]->str])<<endl;
                }
            }
            else{
                codegen(node->children[2]);
                pushl("%eax");
                codegen(node->children[4]);
                popl("%ebx");
                cout<<"movl %eax, -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp, %rbx, 4)"<<endl;
            }
        }
        else if(node->nt == intconst){
            genconst(node->str);
        }
        else if(node->nt == arg_list){
            if(node->nchild == 3){
                codegen(node->children[2]);
                if(narg>6){
                    pushl("%eax");
                    //cout<<1<<endl;
                }
                else{
                    pushl(getpara(narg-1));
                    cout<<"movl %eax, "<<getpara(narg-1)<<endl;
                }
                narg--;
                codegen(node->children[0]);   
            }
            else{
                codegen(node->children[0]);
                pushl(getpara(narg-1));
                cout<<"movl %eax, "<<getpara(narg-1)<<endl;
                //cout<<2<<endl;
            }
        }
        else if(node->nt == func_decl){
            offs = 0;
            npara = 0;
            retu = 1;
            symtab.clear();
            paramtab.clear();
            arraysize.clear();
            if(node->children[1]->children[0]->str == "main"){
                genlabel(".LC0");
                cout<<".string	\"%d\\n\""<<endl;
            }
            cout<<".text"<<endl;
            cout<<".globl	"<< node->children[1]->children[0]->str <<endl;
            cout<<".type	"<< node->children[1]->children[0]->str <<", @function"<<endl;
            genlabel(node->children[1]->children[0]->str);
            enter();
            codegen(node->children[3]);
            funtab[node->children[1]->children[0]->str] = npara;
            //cout<<npara<<node->children[1]->children[0]->str<<endl;
            codegen(node->children[5]);
            if(retu){
                cout<<"movl	$0, %eax"<<endl;
                cout<<"leave"<<endl;
                cout<<"ret"<<endl;
            }
        }
        /*else if(node->nt == var_decl){
            //cout<<"oho"<<endl;
            if(node->nchild == 3 || node->nchild == 4){
                symtab[node->children[1]->children[0]->str] = offs; 
                offs += 4;
                cout<<"subq $4, %rsp"<<endl;
                cout<<"movq $0, (%rsp)"<<endl;
                if(node->nchild == 4){
                    codegen(node->children[3]);
                }
            }
        }*/
        else if(node->nt == local_decl){
            //cout<<"oho"<<endl;
            if(node->nchild == 3){
                offs += 4;
                symtab[node->children[1]->children[0]->str] = offs; 
                //cout<< node->children[1]->children[0]->str << endl;
                cout<<"subq $4, %rsp"<<endl;
                cout<<"movl $0, (%rsp)"<<endl;
            }
            else{
                int size = stoi(node->children[3]->children[0]->children[0]->children[0]->str);
                offs += 4 * size;
                cout<<"subq $"<<4*size<<", %rsp"<<endl;
                symtab[node->children[1]->children[0]->str] = offs; 
                //cout<< node->children[1]->children[0]->str << endl;
                arraysize[node->children[1]->children[0]->str] = 4 * size;
            }
        }
        else if(node->nt == Pexpr && node->children[0]->nt == identifier){
            struct node* child = node->children[0]->children[0];
            if(symtab.find(child->str) != symtab.end()){
                //cout<<child->str<<endl;
                cout<<"movl -"<<symtab[child->str]<<"(%rbp), %eax"<<endl;
            }
            else{
                cout<<"movl "<<getpara(paramtab[child->str])<<", %eax"<<endl;
            }
        }
        else if(node->nt == param){
            struct node* child = node->children[1]->children[0];
            paramtab[child->str] = npara;
            npara++;
        }
        else if(node->nt == print_stmt){
            struct node* child = node->children[4]->children[0];
            if(symtab.find(child->str) != symtab.end()){
                cout<<"movl -"<<symtab[child->str]<<"(%rbp), %eax"<<endl;
            }
            else{
                cout<<"movl "<<getpara(paramtab[child->str])<<", %eax"<<endl;
            }
            for(int i=0; i<6; i++){
                pushl(getpara(i));
            }
            cout<<"movl %eax, %esi"<<endl;
            cout<<"leaq	.LC0(%rip), %rdi"<<endl;
            cout<<"movl	$0, %eax"<<endl;
            cout<<"call	printf@PLT"<<endl;
            for(int i=5; i>=0; i--){
                popl(getpara(i));
            }
        }
        else if(node->nt == return_stmt){
            if(node->nchild == 3){
                retu = 0;
                codegen(node->children[1]);
                cout<<"leave"<<endl;
                cout<<"ret"<<endl;
            }
        }
        else{
            rest:
            for(int i=0;i<node->nchild;i++){
                codegen(node->children[i]);
            }
        }
    }

%}

%%

program
    : decl_list {$$ = cons_rep(program, 1, new struct node*[1] {$1});codegen($$);}
    ; 

decl_list
    : decl_list decl    {$$ = cons_rep(decl_list, 2, new struct node*[2] {$1, $2});}
    | decl  {$$ = cons_rep(decl_list, 1, new struct node*[1] {$1});}
    ;

decl
    : var_decl  {$$ = cons_rep(decl, 1, new struct node*[1] {$1});} 
    | func_decl {$$ = cons_rep(decl, 1, new struct node*[1] {$1});}
    | struct_decl   {$$ = cons_rep(decl, 1, new struct node*[1] {$1});}
    ;

struct_decl
    : STRUCT identifier LCURLY local_decls RCURLY SEMICOLON  {$$ = cons_rep(struct_decl, 6, new struct node*[6] {cons_lex(Struct), $2, cons_lex(lcurly), $4, cons_lex(rcurly), cons_lex(semicolon)});}
    ;

var_decl
    : type_spec identifier SEMICOLON    {$$ = cons_rep(var_decl, 3, new struct node*[3] {$1, $2, cons_lex(semicolon)});}
    | type_spec identifier COMMA var_decl   {$$ = cons_rep(var_decl, 4, new struct node*[4] {$1, $2, cons_lex(comma), $4});}
    | type_spec identifier LBRACKET integerLit RBRACKET SEMICOLON   {$$ = cons_rep(var_decl, 6, new struct node*[6] {$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(semicolon)});}
    | type_spec identifier LBRACKET integerLit RBRACKET COMMA var_decl  {$$ = cons_rep(var_decl, 7, new struct node*[7] {$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(comma), $7});}
    ;

type_spec
    : extern_spec VOID {$$ = cons_rep(type_spec, 2, new struct node*[2] {$1, cons_lex(Void)});}
    | extern_spec INT   {$$ = cons_rep(type_spec, 2, new struct node*[2] {$1, cons_lex(Int)});}
    | extern_spec FLOAT {$$ = cons_rep(type_spec, 2, new struct node*[2] {$1, cons_lex(Float)});}
    | extern_spec VOID STAR {$$ = cons_rep(type_spec, 3, new struct node*[3] {$1, cons_lex(Void), cons_lex(star)});}
    | extern_spec INT STAR  {$$ = cons_rep(type_spec, 3, new struct node*[3] {$1, cons_lex(Int), cons_lex(star)});}
    | extern_spec FLOAT STAR    {$$ = cons_rep(type_spec, 3, new struct node*[3] {$1, cons_lex(Float), cons_lex(star)});}
    | STRUCT identifier {$$ = cons_rep(type_spec, 2, new struct node*[2] {cons_lex(Struct), $2});}  
    | STRUCT identifier STAR    {$$ = cons_rep(type_spec, 3, new struct node*[3] {cons_lex(Struct), $2, cons_lex(star)});}
    ;   

extern_spec
    : EXTERN    {$$ = cons_rep(extern_spec, 1, new struct node*[1] {cons_lex(Extern)});}
    | /*empty*/ {$$ = cons_rep(extern_spec, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

func_decl
    : type_spec identifier LBRACES params RBRACES compound_stmt {$$ = cons_rep(func_decl, 6, new struct node*[6] {$1, $2, cons_lex(lbraces), $4, cons_lex(rbraces), $6});}
    ;

params
    : param_list    {$$ = cons_rep(params, 1, new struct node*[1] {$1});}
    | /*empty*/ {$$ = cons_rep(params, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

param_list
    : param_list COMMA param    {$$ = cons_rep(param_list, 3, new struct node*[3] {$1, cons_lex(comma), $3});}
    | param {$$ = cons_rep(param_list, 1, new struct node*[1] {$1});}
    ;

param
    : type_spec identifier  {$$ = cons_rep(param, 2, new struct node*[2] {$1, $2});}
    | type_spec identifier LBRACKET RBRACKET    {$$ = cons_rep(param, 4, new struct node*[4] {$1, $2, cons_lex(lbracket), cons_lex(rbracket)});}
    ;

stmt_list
    : stmt_list stmt   {$$ = cons_rep(stmt_list, 2, new struct node*[2] {$1, $2});}
    | stmt  {$$ = cons_rep(stmt_list, 1, new struct node*[1] {$1});}
    ;

stmt
    : assign_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | compound_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | if_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | while_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | switch_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | return_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | break_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | continue_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | dowhile_stmt  {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | print_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | incr_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | decr_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    ;

while_stmt
    : WHILE LBRACES expr RBRACES stmt   {$$ = cons_rep(while_stmt, 5, new struct node*[5] {cons_lex(While), cons_lex(lbraces), $3, cons_lex(rbraces), $5});}
    ;

dowhile_stmt
    : DO stmt WHILE LBRACES expr RBRACES SEMICOLON  {$$ = cons_rep(dowhile_stmt, 7, new struct node*[7] {cons_lex(Do), $2, cons_lex(While), cons_lex(lbraces), $5, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

print_stmt
    : PRINTF LBRACES format_specifier COMMA identifier RBRACES SEMICOLON    {$$ = cons_rep(print_stmt, 7, new struct node*[7] {cons_lex(Printf), cons_lex(lbraces), $3, cons_lex(comma), $5, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

format_specifier
    : FRMT_SPEC {$$ = cons_rep(format_specifier, 1, new struct node*[1] {cons_lex(frmt_spec)});}
    ;

compound_stmt  
    : LCURLY local_decls stmt_list RCURLY   {$$ = cons_rep(compound_stmt, 4, new struct node*[4] {cons_lex(lcurly), $2, $3, cons_lex(rcurly)});}
    ;

local_decls
    : local_decls local_decl  {$$ = cons_rep(local_decls, 2, new struct node*[2] {$1, $2});}
    | /*empty*/ {$$ = cons_rep(local_decls, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

local_decl
    : type_spec identifier SEMICOLON    {$$ = cons_rep(local_decl, 3, new struct node*[3] {$1, $2, cons_lex(semicolon)});}
    | type_spec identifier LBRACKET expr RBRACKET SEMICOLON {$$ = cons_rep(local_decl, 6, new struct node*[6] {$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(semicolon)});}
    ;

if_stmt
    : IF LBRACES expr RBRACES stmt  {$$ = cons_rep(if_stmt, 5, new struct node*[5] {cons_lex(If), cons_lex(lbraces), $3, cons_lex(rbraces), $5});}
    | IF LBRACES expr RBRACES stmt ELSE stmt    {$$ = cons_rep(if_stmt, 7, new struct node*[7] {cons_lex(If), cons_lex(lbraces), $3, cons_lex(rbraces), $5, cons_lex(Else), $7});}
    ;

return_stmt
    : RETURN SEMICOLON  {$$ = cons_rep(return_stmt, 2, new struct node*[2] {cons_lex(Return), cons_lex(semicolon)});}
    | RETURN expr SEMICOLON {$$ = cons_rep(return_stmt, 3, new struct node*[3] {cons_lex(Return), $2, cons_lex(semicolon)});}
    ;

break_stmt
    : BREAK SEMICOLON   {$$ = cons_rep(break_stmt, 2, new struct node*[2] {cons_lex(Break), cons_lex(semicolon)});}
    ;

continue_stmt
    : CONTINUE SEMICOLON    {$$ = cons_rep(continue_stmt, 2, new struct node*[2] {cons_lex(Continue), cons_lex(semicolon)});}
    ;

switch_stmt
    : SWITCH LBRACES expr RBRACES LCURLY compound_case default_case RCURLY  {$$ = cons_rep(switch_stmt, 8, new struct node*[8] {cons_lex(Switch), cons_lex(lbraces), $3, cons_lex(rbraces), cons_lex(lcurly), $6, $7, cons_lex(rcurly)});}
    ;

compound_case 
    : single_case compound_case {$$ = cons_rep(compound_case, 2, new struct node*[2] {$1, $2});}
    | single_case   {$$ = cons_rep(compound_case, 1, new struct node*[1] {$1});}
    ;

single_case
    : CASE integerLit COLON stmt_list   {$$ = cons_rep(single_case, 4, new struct node*[4] {cons_lex(Case), $2, cons_lex(colon), $4});}
    ;

default_case
    : DEFAULT COLON stmt_list   {$$ = cons_rep(default_case, 3, new struct node*[3] {cons_lex(Default), cons_lex(colon), $3});}
    ;

assign_stmt
    : identifier EQUAL expr SEMICOLON   {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 2, new struct node*[2] {$1, $3}), cons_lex(semicolon)});}
    | identifier LBRACKET expr RBRACKET EQUAL expr SEMICOLON    {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 5, new struct node*[5] {$1, cons_lex(lbracket), $3, cons_lex(rbracket), $6}), cons_lex(semicolon)});}
    | identifier POIOP identifier EQUAL expr SEMICOLON  {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 4, new struct node*[4] {$1, cons_lex(poiop), $3, $5}), cons_lex(semicolon)});}
    | identifier DOT identifier EQUAL expr SEMICOLON    {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 4, new struct node*[4] {$1, cons_lex(dot), $3, $5}), cons_lex(semicolon)});}
    ;

incr_stmt
    : identifier INCOP SEMICOLON    {$$ = cons_rep(incr_stmt, 3, new struct node*[3] {$1, cons_lex(incop), cons_lex(semicolon)});}
    ;

decr_stmt
    : identifier DECOP SEMICOLON    {$$ = cons_rep(decr_stmt, 3, new struct node*[3] {$1, cons_lex(decop), cons_lex(semicolon)});}
    ;

expr
    : Pexpr LESSER Pexpr    {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(lesser, 2, new struct node*[2] {$1, $3})});}
    | Pexpr GREATER Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(Greater, 2, new struct node*[2] {$1, $3})});}
    | Pexpr LEQOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(leqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr GEQOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(geqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr OROP Pexpr  {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(orop, 2, new struct node*[2] {$1, $3})});}
    | SIZEOF LBRACES Pexpr RBRACES  {$$ = cons_rep(expr, 4, new struct node*[4] {cons_lex(Sizeof), cons_lex(lbraces), $3, cons_lex(rbraces)});}
    | Pexpr EQOP Pexpr  {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(eqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr NEQOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(neqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr COMOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(comop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr ANDOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(andop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr POIOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(poiop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr ADD Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(add, 2, new struct node*[2] {$1, $3})});}
    | Pexpr SUB Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(sub, 2, new struct node*[2] {$1, $3})});}
    | Pexpr STAR Pexpr  {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(star, 2, new struct node*[2] {$1, $3})});}
    | Pexpr DIV Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(Div, 2, new struct node*[2] {$1, $3})});}
    | Pexpr MOD Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(mod, 2, new struct node*[2] {$1, $3})});}
    | NOT Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(Not), $2});}
    | SUB Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(sub), $2});}
    | ADD Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(add), $2});}
    | STAR Pexpr    {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(star), $2});}
    | AND Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(And), $2});}
    | Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {$1});}
    | identifier LBRACES args RBRACES   {$$ = cons_rep(expr, 4, new struct node*[4] {$1, cons_lex(lbraces), $3, cons_lex(rbraces)});}
    | identifier LBRACKET expr RBRACKET {$$ = cons_rep(expr, 4, new struct node*[4] {$1, cons_lex(lbracket), $3, cons_lex(rbracket)});}
    ;

Pexpr
    : integerLit    {$$ = cons_rep(Pexpr, 1, new struct node*[1] {$1});}
    | floatLit  {$$ = cons_rep(Pexpr, 1, new struct node*[1] {$1});}
    | identifier    {$$ = cons_rep(Pexpr, 1, new struct node*[1] {$1});}
    | LBRACES expr RBRACES  {$$ = cons_rep(Pexpr, 3, new struct node*[3] {cons_lex(lbraces), $2, cons_lex(rbraces)});}
    ;

arg_list
    : arg_list COMMA expr  {$$ = cons_rep(arg_list, 3, new struct node*[3] {$1, cons_lex(comma), $3});}
    | expr  {$$ = cons_rep(arg_list, 1, new struct node*[1] {$1});}
    ;

args 
    : arg_list  {$$ = cons_rep(args, 1, new struct node*[1] {$1});}
    | /*empty*/ {$$ = cons_rep(args, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

integerLit
    : INTCONST  {$$ = cons_rep(integerLit, 1, new struct node*[1] {cons_lexstr(intconst, yytext)});}
    ;

floatLit
    : FLOATCONST    {$$ = cons_rep(floatLit, 1, new struct node*[1] {cons_lexstr(floatconst, yytext)});}
    ;

identifier
    : ID    {$$ = cons_rep(identifier, 1, new struct node*[1] {cons_lexstr(id, yytext)});}
    ;

%%

extern FILE *yyin;

void yyerror(char * s) {
    syntax = 1;
}

int main() {
    yyparse();
    
    if(syntax!=0){
        printf("syntax error\n");
        return 0;
    }
    return 0;
}